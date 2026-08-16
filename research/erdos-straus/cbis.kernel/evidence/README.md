# cbis.kernel model-escape evidence

This directory stores **bounded model-escape candidates** produced only when
`cbis_escape.py --record` is explicitly requested.

A record means all of the following were true at the time it was written:

1. an exact positive Erdős–Straus decomposition was found and independently
   checked by integer cross multiplication;
2. no Type A/B witness was found through the recorded finite depth `K`;
3. if the C `cbis-audit` binary was available, its Type A/B result did not
   disagree with the independent Python audit.

A record does **not** mean that Type A/B is false. A deeper Type A/B witness
may exist. The canonical example is `p = 9,658,489`: Type A/B is unseen at
`K=400`, while the known minimal Type B witness occurs later at `k=2622`.

Schema: `ES-MODEL-ESCAPE-v1`.

Runtime files are content-addressed as `ME-<sha256-prefix>.json`. The journal
is append-only. Generated evidence is research data, not part of the
W/I/N/L cover and not part of `ES-LETTER-v1` identity.
