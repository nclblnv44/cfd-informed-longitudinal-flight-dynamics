# Provenienza dei dati

`cfd_results.csv` è l'output della campagna Fluent svolta per questo progetto. SHA-256 del CSV sorgente verificato il 1 ottobre 2026:

```text
4F11AC5379683E1F67B1A118AEE08ABAE75AD6BD6D1412EF40DD9A0021D90472
```

Il CSV contiene più mesh; `scripts/importPolar.m` seleziona le nove righe della mesh **449×129** tra **-4° e 12°**. Gli altri campioni non costituiscono tutti una polare completa.

`reference/conditions.json` registra le condizioni della CFD, tra cui densità circa **2.1274 kg/m³**. Il modello dinamico MATLAB usa **1.225 kg/m³**. `reference/linear_model.json` conserva fit della fase CFD; il simulatore rigenera il proprio fit locale dal CSV. `reference/validation_metrics.json` riporta le metriche della comparazione sperimentale. Le figure di validazione nel report CFD sono derivate dal confronto, non dati sperimentali originali.

I dati sperimentali di Ladson con transizione forzata provengono dalla [NASA Turbulence Modeling Resource - NACA 0012 validation](https://tmbwg.github.io/turbmodels/naca0012_val.html), che rimanda anche a NASA TM 4074. Le copie grezze e la tabella punto per punto con valori sperimentali non fanno parte del repository pubblico; la fonte è accessibile dal link NASA TMR.

Mesh, casi, soluzioni Fluent e storie iterative restano nell'archivio della campagna originale, fuori da questo repository. `runProject` riproduce l'analisi MATLAB dal CSV, non riesegue la campagna Fluent. I file `data/*.mat` e `results/*.mat` sono derivati rigenerabili.
