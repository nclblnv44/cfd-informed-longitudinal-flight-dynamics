# Effetto della velocita di beccheggio e sensibilita a Iyy

**Data:** 1 ottobre 2026. **Ambiente:** MATLAB R2026a. Questa analisi estende il modello longitudinale e conserva il caso precedente come riferimento numerico.

## Ipotesi fisica

Quando il velivolo beccheggia con q_pitch positivo (muso verso l'alto), la coda posta dietro al baricentro si muove verso il basso. Nella stima quasi stazionaria, il suo angolo d'attacco efficace aumenta di kq*lt*q_pitch/V:

```text
alpha_t = (1 - downwashGradient)*alpha + i_t + tau_e*delta_e
          + kq*lt*q_pitch/V
CL_tail = a_t*alpha_t
L_tail = qbar*eta_t*St*CL_tail
M = qbar*S*c_bar*(cm_CFD - eta_t*VH*CL_tail)
```

L'aumento della portanza di coda genera un momento negativo e contrasta il beccheggio positivo. `kq=1` rappresenta la sola stima geometrica; `kq=0` restituisce il modello precedente. Con `qhat=q_pitch*c_bar/(2V)`, la derivata del momento **di questo modello** e `Cm_q=-2*kq*eta_t*VH*a_t*lt/c_bar`, pari a **-4.534111** per `kq=1`. Non proviene dalla polare CFD statica e non e una misura sperimentale del velivolo. La stessa correzione modifica la portanza della coda e quindi la dinamica di traiettoria.

Al trim `q_pitch=0`: angolo d'attacco **3.572781 deg**, elevatore **-4.821444 deg**, portanza totale **5886 N** e spinta **330.350994 N** non cambiano. `Iyy=1000 kg*m^2` resta una stima, non un valore identificato.

## Esperimento riproducibile

Tutti i casi usano il medesimo trim, spinta costante, impulso relativo di elevatore **-0.5 deg** da 2 a 2.5 s, durata 20 s e tolleranze `ode45` uguali. Il confronto varia `kq = 0, 0.5, 1, 1.5` a `Iyy=1000 kg*m^2`; poi varia `Iyy = 750, 1000, 1250 kg*m^2` a `kq=1`. Gli intervalli sono scenari di sensibilita scelti per il modello didattico, non incertezze misurate.

| kq | Iyy [kg*m^2] | Max abs(Delta alpha) [deg] | Max abs(q_pitch) [deg/s] | Max abs(Delta V) [m/s] | Delta h a 20 s [m] |
|---:|---:|---:|---:|---:|---:|
| 0 | 1000 | 0.514421 | 2.408130 | 0.346080 | -1.672701 |
| 0.5 | 1000 | 0.415299 | 1.955523 | 0.324842 | -1.504682 |
| 1 | 1000 | 0.346727 | 1.639474 | 0.306579 | -1.275307 |
| 1.5 | 1000 | 0.297359 | 1.407535 | 0.290818 | -1.034887 |
| 1 | 750 | 0.346664 | 1.790189 | 0.305482 | -1.266096 |
| 1 | 1250 | 0.338708 | 1.529325 | 0.307666 | -1.284283 |

Il caso `kq=0, Iyy=1000` riproduce i massimi documentati prima della modifica entro **5e-5** nelle rispettive unita. A `kq=1`, il picco della velocita di beccheggio e dell'angolo d'attacco e inferiore al riferimento; l'effetto sul modo lento e diverso da quello sul rapido. La sensibilita a `Iyy` cambia soprattutto il picco di `q_pitch` e la frequenza del modo rapido in questi tre scenari.

La linearizzazione locale a quattro stati, che esclude la quota, fornisce per `kq=1, Iyy=1000`:

| Modo | Autovalori [1/s] | Periodo [s] | Tempo di decadimento e-fold [s] |
|---|---|---:|---:|
| Rapido | -3.257524 +/- 5.917321 i | 1.061829 | 0.306982 |
| Lento | -0.007106 +/- 0.237724 i | 26.430613 | 140.721646 |

Per riferimento, il modello `kq=0` aveva il modo rapido `-1.709485 +/- 5.770799 i` e il lento `-0.007235 +/- 0.266817 i`. Entrambi i modi nominali nuovi hanno parte reale negativa nel modello linearizzato locale; questo non valida sperimentalmente la stabilita del velivolo. I 20 s dell'impulso coprono meno di un periodo del modo lento e non ne mostrano l'assestamento.

![Confronto di q_pitch e Iyy](../results/pitch_damping_inertia_comparison.png)

## Controlli eseguiti

`runProject` e stato completato in MATLAB R2026a anche da una cartella corrente esterna al progetto. Il trim rigenerato ha errore di portanza **3.39e-9 N** e momento **1.76e-13 N*m**. Senza impulso, lo scostamento massimo di velocita in 20 s e **2.86e-11 m/s**. Nei sei casi del confronto, gli stati sono finiti, lo stato pre-impulso resta al trim entro **1e-7** nelle unita dei singoli stati e i raccordi tra i tre intervalli sono continui entro **1e-12**. Un controllo separato ha verificato che `q_pitch>0` aumenta la portanza della coda e rende il momento piu negativo, con segno opposto per `q_pitch<0`.

Per riprodurre l'analisi dalla radice del progetto, eseguire `runProject` oppure `setupProject` e poi `comparePitchDampingAndInertia`. La procedura salva il riepilogo dettagliato, i casi MAT e il grafico in `results/`. Lo script `analyseElevatorResponse` analizza il caso nominale rigenerato, senza ripetere quella simulazione.

## Limiti e passo successivo

La stima non include ritardi aerodinamici, variazione dinamica del downwash, derivate di beccheggio dell'ala o identificazione di `Iyy`. Restano densita costante, baricentro al quarto di corda, spinta lungo la traiettoria e assenza della resistenza di coda/fusoliera. La polare CFD non va estrapolata oltre **-4..12 deg**. La validazione sperimentale disponibile riguarda il profilo, non la risposta dinamica del velivolo.

La portanza CFD non lineare e la correzione di ala finita sono state poi integrate e confrontate con il modello lineare a trim distinti; vedere il [report del progetto](REPORT_PROGETTO.md).
