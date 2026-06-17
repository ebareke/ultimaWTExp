#!/usr/bin/env python3
"""
dump_versions.py — merge every process's versions.yml into one provenance
document (and, with --html, a small table for MultiQC). Intentionally
dependency-free (no PyYAML): the versions.yml blocks are simple
`"process": {tool: version}` two-level scalars.
"""
import sys
import glob
import os


def parse_into(path, merged):
    """Accumulate every `"process": {tool: version}` block in one file.

    Handles a single versions.yml or many concatenated together (collectFile),
    so multiple top-level blocks per file are all captured (not just the last).
    """
    process = None
    with open(path) as fh:
        for line in fh:
            raw = line.rstrip('\n')
            if not raw.strip():
                continue
            if not raw.startswith(' '):
                process = raw.strip().strip('"').rstrip(':')
                merged.setdefault(process, {})
            elif ':' in raw and process is not None:
                k, v = raw.strip().split(':', 1)
                merged[process][k.strip()] = v.strip().strip('"')


def collect(args):
    files = []
    for a in args:
        files.extend(glob.glob(a) if any(c in a for c in '*?[') else [a])
    merged = {}
    for f in files:
        if os.path.isfile(f):
            parse_into(f, merged)
    merged['Workflow'] = {'ultimaWTExp': '1.0.0', 'Nextflow': os.environ.get('NXF_VER', 'NA')}
    return merged


def main():
    html = False
    args = sys.argv[1:]
    if args and args[0] == '--html':
        html = True
        args = args[1:]
    merged = collect(args)

    if html:
        print('<dl class="dl-horizontal">')
        for proc in sorted(merged):
            for tool, ver in sorted(merged[proc].items()):
                print(f'  <dt>{tool}</dt><dd><samp>{ver}</samp></dd>')
        print('</dl>')
    else:
        for proc in sorted(merged):
            print(f'{proc}:')
            for tool, ver in sorted(merged[proc].items()):
                print(f'  {tool}: {ver}')


if __name__ == '__main__':
    main()
