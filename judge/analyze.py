import re
import sys
import argparse
from collections import deque

# ==============================================================================
#  ARCHITECTURE CONFIGURATION
# ==============================================================================
# Define MIPS config once to reuse
MIPS_CONFIG = {
    'call':           {'jal', 'jalr', 'bal'},
    'syscall':        {'syscall'},
    'terminators':    {'j', 'b', 'jr', 'beq', 'bne'}, 
    'has_delay_slot': True,
    'syscall_reg':    r'v0',
}

ARCH_CONFIG = {
    'mips':   MIPS_CONFIG,
    'mipsel': MIPS_CONFIG,
    'x86': { 
        'call':           {'call', 'callq'},
        'syscall':        {'syscall', 'int', 'sysenter'},
        'terminators':    {'ret', 'retq', 'jmp'},
        'has_delay_slot': False,
        'syscall_reg':    r'[er]?ax', 
    },
    'arm': { 
        'call':           {'bl', 'blx'},
        'syscall':        {'svc', 'swi'},
        'terminators':    {'b', 'bx', 'pop'},
        'has_delay_slot': False,
        'syscall_reg':    r'r7',
    },
    'aarch64': { 
        'call':           {'bl', 'blr'},
        'syscall':        {'svc'},
        'terminators':    {'b', 'ret'},
        'has_delay_slot': False,
        'syscall_reg':    r'[xw]8', 
    },
    's390x': {
        'call':           {'brasl', 'basr', 'bras'}, 
        'syscall':        {'svc'},
        'terminators':    {'br', 'jg', 'j', 'b'},    
        'has_delay_slot': False,
        'syscall_reg':    r'r1', 
    },
}

class AssemblyAnalyzer:
    def __init__(self, filepath, arch='mips'):
        self.filepath = filepath
        self.arch_name = arch if arch in ARCH_CONFIG else 'mips' 
        # Safety fallback if 'mips' is missing from config (handled above now)
        if self.arch_name not in ARCH_CONFIG:
             print(f"Warning: Architecture '{self.arch_name}' not found in config. Defaulting to mipsel logic if available or crashing.")
        self.spec = ARCH_CONFIG.get(self.arch_name, ARCH_CONFIG.get('mipsel'))
        
        self.functions = {} 
        self.label_order = []
        self.raw_blocks = {}
        # Known standard entry points or section markers to keep logic clean
        self.identified_funcs = set(['main', '_start', '__start', '_init', '_fini'])
        
        self._parse_file()
        self._finalize_functions()
        self._build_function_graph()

    def _is_terminator(self, mnem, args):
        """
        Determines if an instruction stops control flow from falling through to the next line.
        """
        if mnem in self.spec['terminators']:
            # ARM pop special case: only a terminator if it loads into PC
            if self.arch_name == 'arm' and mnem == 'pop':
                # pop {..., pc} -> return (terminator)
                # pop {r7} -> standard pop (not terminator)
                if 'pc' not in args and 'r15' not in args:
                    return False

            # MIPS beq 0,0 special case (Unconditional Jump via Conditional Branch)
            if mnem in ['beq', 'bne'] and self.arch_name in ['mips', 'mipsel']:
                cleaned = re.sub(r'[$,]', ' ', args).split()
                if len(cleaned) >= 2:
                    op1, op2 = cleaned[0], cleaned[1]
                    zeros = ['zero', '0']
                    if op1 in zeros and op2 in zeros:
                        return True
                return False
            return True
        return False

    def _extract_immediate(self, args_str):
        """Extracts the last immediate value from a string."""
        # Remove memory references [r0, #4] -> r0, #4
        args_no_mem = re.sub(r'\(.*?\)', '', args_str)
        args_no_mem = re.sub(r'\[.*?\]', '', args_no_mem)
        
        # Find hex or decimal numbers
        nums = re.findall(r'(?:0x[0-9a-fA-F]+)|(?:\b-?\d+\b)', args_no_mem)
        if nums:
            val_str = nums[-1]
            try:
                # Handle hex and decimal conversion
                val = int(val_str, 16) if val_str.startswith('0x') else int(val_str)
                return str(val)
            except:
                pass
        return None

    def _scan_block_for_reg(self, block, reg_pattern):
        """
        Backtracking to find register load with smart instruction classification.
        Returns the value if found, '?' if lost (destructive op), or None if not found in block.
        """
        reg_regex = re.compile(r'\b' + reg_pattern + r'\b')

        # === Heuristics for Instruction Classification ===
        # Instructions that WRITE to register (we can potentially get value from them)
        write_mnems = {
            'mov', 'mvn', 'add', 'sub', 'li', 'la', 'or', 'and', 'eor', 'xor', 
            'lsl', 'lsr', 'asr', 'ror', 'clr', 'move'
        }
        # Instructions that READ register (value doesn't change, keep looking back)
        read_mnems = {
            'cmp', 'cmn', 'tst', 'teq', 'str', 'push', 'beq', 'bne', 'sw', 'sd', 
            'st', 'std', 'test', 'sh', 'sb'
        }
        # Instructions that DESTROY register content (load from memory/stack -> unknown value for static analysis)
        destructive_mnems = {
            'ldr', 'pop', 'ldm', 'lw', 'ld', 'lh', 'lb', 'lbu', 'lhu'
        }

        for i in range(len(block) - 1, -1, -1):
            instr = block[i]
            if instr['type'] != 'instr': continue
            
            mnem = instr['mnem'] # Already lowercased in _parse_file
            args = instr['args']
            
            # Clean args for regex match (remove register prefixes like $ or %)
            clean_args = args.replace('$', '').replace('%', '')
            
            if reg_regex.search(clean_args):
                # 1. Destructive Op: value comes from memory/stack. Logic ends.
                if any(dm in mnem for dm in destructive_mnems):
                    return '?'

                # 2. Write Op: try to extract immediate
                if any(wm in mnem for wm in write_mnems):
                    val = self._extract_immediate(args)
                    if val:
                        # Edge case: mov r7, r7 (no info)
                        if val == reg_pattern.replace('[xw]', '').replace('r', ''):
                             continue
                        return val
                    # Write happened but no immediate (e.g., mov r0, r1) -> Value Unknown
                    return '?'

                # 3. Read Op: Instruction uses reg but doesn't change it. Continue back.
                if any(rm in mnem for rm in read_mnems):
                    continue

                # 4. Fallback: Unknown instruction using the register.
                # Assume it modifies the register. Try to extract immediate just in case.
                val = self._extract_immediate(args)
                if val:
                     if val == reg_pattern.replace('[xw]', '').replace('r', ''):
                         continue
                     return val
                
                return '?' 
        return None

    def _resolve_syscall_val(self, current_label, reg_name, instr_args=""):
        """
        Resolves the syscall number.
        Priority:
        1. Immediate inside the syscall instruction (e.g., svc 0x900000)
        2. Backtracking in current block
        3. Backtracking in immediate predecessor block (if connected)
        """
        # 1. Immediate in instruction (e.g., svc 123), ignoring 0
        if instr_args:
            direct_val = self._extract_immediate(instr_args)
            if direct_val and direct_val != '0':
                return direct_val

        # 2. Scan current block
        curr_block = self.raw_blocks.get(current_label, [])
        val = self._scan_block_for_reg(curr_block, reg_name)
        if val: return val
        
        # 3. Scan previous block (Linear sweep fallback)
        try:
            if not self.label_order: return '?'
            curr_idx = self.label_order.index(current_label)
            if curr_idx == 0: return '?'
            
            prev_label = self.label_order[curr_idx - 1]
            prev_block = self.raw_blocks[prev_label]
            if not prev_block: return '?'
            
            last_instr = prev_block[-1]
            is_connected = False
            
            # Check connection: Fallthrough or explicit branch to current label
            if 'mnem' in last_instr:
                mnem = last_instr['mnem']
                args = last_instr['args']
                if current_label in args: is_connected = True
                elif not self._is_terminator(mnem, args): is_connected = True
            
            if is_connected:
                val = self._scan_block_for_reg(prev_block, reg_name)
                if val: return val

        except Exception:
            pass
        return '?'

    def _parse_file(self):
        try:
            with open(self.filepath, 'r', encoding='utf-8', errors='replace') as f:
                lines = f.readlines()
        except FileNotFoundError:
            print(f"Error: File {self.filepath} not found.")
            sys.exit(1)

        # Regex Patterns
        label_pat = re.compile(r'^[0-9a-fA-F]*\s*<([^>]+)>:$')
        # Instruction pattern: Address: HexBytes... Mnemonic Args
        instr_pat = re.compile(r'^\s*[0-9a-fA-F]+:\s+(?:[0-9a-fA-F]{2,16}\s+)+\s+([a-z0-9._]+)\s*(.*)$')
        reloc_pat = re.compile(r'^\s*[0-9a-fA-F]+:\s+R_[\w_]+\s+(\S+)')
        target_pat = re.compile(r'<([^>+]+)(?:\+0x[0-9a-fA-F]+)?>')

        current_label = None
        is_dead = False
        delay_slot = 0

        for line in lines:
            line = line.strip()

            # 1. Label Detection
            label_match = label_pat.match(line)
            if label_match:
                current_label = label_match.group(1)
                self.label_order.append(current_label)
                self.raw_blocks[current_label] = []
                is_dead = False
                delay_slot = 0
                continue

            if not current_label: continue
            # Note: We don't skip if is_dead is True immediately, 
            # because we might need to parse data/padding to keep block structure,
            # but usually we just want instructions.

            # 2. Relocation Parsing (Priority Logic)
            reloc_match = reloc_pat.match(line)
            if reloc_match:
                if is_dead: continue 

                raw_target = reloc_match.group(1)
                target = raw_target.split('@')[0]
                target = re.sub(r'[+-]0x[0-9a-fA-F]+$', '', target)

                # FILTER: Don't treat section symbols or special objdump markers as functions
                if target.startswith('.') or target.startswith('*') or target == 'ABS' or target == 'UND': 
                    continue
                
                self.identified_funcs.add(target)
                
                # Patch the previous instruction to be a call
                if self.raw_blocks[current_label]:
                    last_entry = self.raw_blocks[current_label][-1]
                    # Only patch if it was interpreted as an instruction or call
                    if last_entry.get('type') in ['instr', 'call']:
                        last_entry['type'] = 'call'
                        last_entry['target'] = target
                        last_entry['is_reloc'] = True 
                        continue
                
                # If no previous instruction (weird), just add as call
                self.raw_blocks[current_label].append({'type': 'call', 'target': target, 'mnem': 'call', 'is_reloc': True})
                continue

            # 3. Instruction Parsing
            instr_match = instr_pat.match(line)
            if instr_match:
                mnem = instr_match.group(1).lower() # Normalize to lowercase
                args = instr_match.group(2)
                
                # === CRITICAL FIX: FILTER DIRECTIVES ===
                # Objdump often lists .word, .byte, .short in code sections.
                # These are NOT instructions.
                if mnem.startswith('.'):
                    continue

                # === FILTER: MIPS NOP encoded as sll 0,0,0 ===
                if self.arch_name in ['mips', 'mipsel'] and mnem == 'sll':
                    # Remove comments first
                    temp_args = args.split('#')[0]
                    # Use Regex to strip ALL whitespace (tabs, spaces), and $
                    # This handles "zero, \tzero, 0" correctly
                    clean_args = re.sub(r'[\s$]', '', temp_args)
                    parts = clean_args.split(',')
                    
                    zeros = {'0', 'zero', 'r0', '0x0'}
                    # If we have 3 args and all are synonyms for zero, treat as NOP
                    if len(parts) == 3 and all(p in zeros for p in parts):
                        continue

                if is_dead: continue

                if delay_slot > 0:
                    delay_slot -= 1
                    if delay_slot == 0: is_dead = True

                self.raw_blocks[current_label].append({
                    'type': 'instr', 
                    'mnem': mnem, 
                    'args': args,
                    'is_reloc': False
                })

                # A. Detect Call (Tentative)
                if mnem in self.spec['call']:
                    target = None
                    if '<' in args:
                        tm = target_pat.search(args)
                        if tm: target = tm.group(1)
                    
                    # FILTER: Noise reduction
                    if target and not target.startswith('.') and not target.startswith('*') and target != 'ABS':
                        self.raw_blocks[current_label][-1]['type'] = 'call'
                        self.raw_blocks[current_label][-1]['target'] = target

                # B. Detect Syscall
                elif mnem in self.spec['syscall']:
                    self.raw_blocks[current_label][-1]['type'] = 'syscall'
                    val = self._resolve_syscall_val(current_label, self.spec['syscall_reg'], args)
                    self.raw_blocks[current_label][-1]['syscall_val'] = val

                # C. Detect Terminator
                if self._is_terminator(mnem, args):
                    if self.spec['has_delay_slot']:
                        if delay_slot == 0: delay_slot = 1
                    else:
                        # For ARM/x86, we stop tracking "flow" strictly inside a block 
                        # but we DON'T mark is_dead=True because in assembly (especially hand-written),
                        # code might continue after a branch due to literal pools or multiple entry points.
                        # We err on the side of Recall here.
                        pass 

    def _finalize_functions(self):
        """
        Promote call targets to identified functions ONLY if they weren't
        patched by a relocation (or if they are valid local calls).
        """
        for label in self.raw_blocks:
            for item in self.raw_blocks[label]:
                if item.get('type') == 'call':
                    target = item['target']
                    # Final noise filter
                    if not target.startswith('.') and not target.startswith('*') and target != 'ABS':
                        self.identified_funcs.add(target)

    def _build_function_graph(self):
        current_scope = None
        
        for label in self.label_order:
            # We treat every label as a potential function part, 
            # but we group them under the last seen "Identified Function".
            if label in self.identified_funcs or current_scope is None:
                current_scope = label
                if current_scope not in self.functions:
                    self.functions[current_scope] = {
                        'callees': set(), 
                        'instrs': set(), 
                        'syscalls': set()
                    }
            
            for item in self.raw_blocks[label]:
                if 'mnem' in item:
                    self.functions[current_scope]['instrs'].add(item['mnem'])
                
                if item['type'] == 'call':
                    self.functions[current_scope]['callees'].add(item['target'])
                elif item['type'] == 'syscall':
                    val = item['syscall_val']
                    if val != 'unknown':
                        self.functions[current_scope]['syscalls'].add(str(val))
                    else:
                        self.functions[current_scope]['syscalls'].add('?')

    # Getters
    def get_all_functions(self):
        return sorted(list(self.functions.keys()))

    def get_direct_callees(self, func):
        if func not in self.functions: return []
        return sorted(list(self.functions[func]['callees']))

    def get_indirect_callees(self, func):
        if func not in self.functions: return []
        visited = set()
        queue = deque([func])
        result = set()
        while queue:
            curr = queue.popleft()
            if curr in visited: continue
            visited.add(curr)
            if curr != func: result.add(curr)
            if curr in self.functions:
                for child in self.functions[curr]['callees']:
                    if child == func: result.add(child)
                    queue.append(child)
        return sorted(list(result))

    def get_syscalls(self, func):
        if func not in self.functions: return []
        res = sorted(list(self.functions[func]['syscalls']))
        return [r for r in res if r != '?'] + (['?'] if '?' in res else [])

    def get_direct_instrs(self, func):
        if func not in self.functions: return []
        return sorted(list(self.functions[func]['instrs']))

    def get_indirect_instrs(self, func):
        callees = self.get_indirect_callees(func)
        all_instrs = set(self.get_direct_instrs(func))
        for c in callees:
            all_instrs.update(self.get_direct_instrs(c))
        return sorted(list(all_instrs))

    def get_indirect_syscalls(self, func):
        callees = self.get_indirect_callees(func)
        all_syscalls = set(self.get_syscalls(func))
        for c in callees:
            all_syscalls.update(self.get_syscalls(c))
        res = sorted(list(all_syscalls))
        return [r for r in res if r != '?'] + (['?'] if '?' in res else [])

# ==========================================
#  CLI
# ==========================================
def main():
    parser = argparse.ArgumentParser(description="Assembly Static Analyzer & Parser")
    parser.add_argument("file", help="Objdump file (or use - to read from pipe)")
    parser.add_argument("--arch", default="mips", choices=ARCH_CONFIG.keys())
    
    # Modes
    parser.add_argument("--dump-graph", action="store_true")
    parser.add_argument("--list-funcs", action="store_true")
    parser.add_argument("--list-callees", metavar="FUNC")
    parser.add_argument("--list-callees-recursive", metavar="FUNC")
    parser.add_argument("--list-syscalls", metavar="FUNC")
    parser.add_argument("--list-syscalls-recursive", metavar="FUNC")
    parser.add_argument("--list-instrs", metavar="FUNC")
    parser.add_argument("--list-instrs-recursive", metavar="FUNC")

    args = parser.parse_args()
    analyzer = AssemblyAnalyzer(args.file, args.arch)

    if args.dump_graph:
        for func in analyzer.get_all_functions():
            callees = analyzer.get_direct_callees(func)
            sys_list = analyzer.get_syscalls(func)
            tag = f" [syscall: {','.join(sys_list)}]" if sys_list else ""
            if callees:
                print(f"{func}{tag} -> {', '.join(callees)}")
            else:
                print(f"{func}{tag} (no calls)")

    elif args.list_funcs:
        print("\n".join(analyzer.get_all_functions()))
    elif args.list_callees:
        print(" ".join(analyzer.get_direct_callees(args.list_callees)))
    elif args.list_callees_recursive:
        print(" ".join(analyzer.get_indirect_callees(args.list_callees_recursive)))
    elif args.list_syscalls:
        print(" ".join(analyzer.get_syscalls(args.list_syscalls)))
    elif args.list_syscalls_recursive:
        print(" ".join(analyzer.get_indirect_syscalls(args.list_syscalls_recursive)))
    elif args.list_instrs:
        print(" ".join(analyzer.get_direct_instrs(args.list_instrs)))
    elif args.list_instrs_recursive:
        print(" ".join(analyzer.get_indirect_instrs(args.list_instrs_recursive)))

if __name__ == "__main__":
    main()
