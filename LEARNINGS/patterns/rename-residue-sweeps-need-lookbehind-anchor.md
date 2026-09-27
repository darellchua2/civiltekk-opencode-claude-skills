# Pattern: rename residue sweeps need a lookbehind anchor

Residue sweeps for `X-skill → civiltekk-X-skill` renames false-positive on
every legitimate new-name use (the old name is a suffix of the new; the first
#603 sweep produced 20+ false hits across registry/presets/agents). Fix:
`grep -rP '(?<!civiltekk-)(?<!/)X-skill'`. Standard gate for any further
civiltekk- consolidation wave.
