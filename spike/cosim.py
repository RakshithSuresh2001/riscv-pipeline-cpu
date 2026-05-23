import re

def parse_spike(path):
    commits = []
    with open(path) as f:
        for line in f:
            m = re.match(r'core\s+\d+:\s+\d+\s+0x8[0-9a-f]+\s+\(0x[0-9a-f]+\)\s+x(\d+)\s+0x([0-9a-f]+)', line)
            if m:
                commits.append({'rd': int(m.group(1)), 'val': int(m.group(2), 16)})
    return commits

def parse_rtl(path):
    commits = []
    with open(path) as f:
        for line in f:
            m = re.match(r'RTL rd=x(\d+)\s+val=0x([0-9a-f]+)', line)
            if m:
                commits.append({'rd': int(m.group(1)), 'val': int(m.group(2), 16)})
    return commits

spike = parse_spike('spike/golden.log')
rtl   = parse_rtl('spike/rtl.log')

print(f"Spike commits: {len(spike)}")
print(f"RTL   commits: {len(rtl)}")
print()

pass_count = 0
fail_count = 0

for i, (s, r) in enumerate(zip(spike, rtl)):
    match = (s['rd'] == r['rd']) and (s['val'] == r['val'])
    if match:
        pass_count += 1
        print(f"[{i:2d}] PASS  rd=x{s['rd']:<2d}  val=0x{s['val']:08x}")
    else:
        fail_count += 1
        print(f"[{i:2d}] FAIL  rd=x{s['rd']:<2d}")
        print(f"       Spike val=0x{s['val']:08x}")
        print(f"       RTL   val=0x{r['val']:08x}")

if len(spike) != len(rtl):
    print(f"\nWARN: commit count mismatch (spike={len(spike)} rtl={len(rtl)})")

print(f"\n=== Co-sim: {pass_count} PASS, {fail_count} FAIL ===")
