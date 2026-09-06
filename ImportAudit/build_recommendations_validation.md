# Build Recommendations Import Validation

| Check | Result |
| --- | --- |
| Workbook character builds found | 91 |
| Matched existing character IDs | 95 |
| Unmatched workbook characters | 1 |
| Light Cone recommendations | 608 |
| Matched Light Cone recommendations | 604 |
| Unmatched Light Cone names | 3 |
| Matched relic-set recommendations | 251 |
| Unmatched relic-set names | 28 |
| Matched planar-set recommendations | 364 |
| Unmatched planar-set names | 1 |
| Unknown stat values | 3 |
| Duplicate character keys | 0 |
| Missing required fields | 0 |
| Records with multiple build variants | 1 |
| Validation failed | False |

## Unresolved Items

### Unmatched Characters
- `{"context": "Wind row 4 Robin Summeretto", "name": "Robin Summeretto", "element": "Wind", "path": "Remembrance", "expected_element": "Wind", "expected_path": "Memory"}`

### Unmatched Light Cones
- `A Little Getaway`: Fire row 56 Sparxie, Imaginary row 4 Silver Wolf LV.999, Physical row 4 Evanescia
- `Any High Base HP / DEF Light Cone`: Fire row 243 Himeko
- `Rise and Sing`: Wind row 4 Robin Summeretto

### Unmatched Relic Sets
- `ATK% Set + 2-PC: ATK% Set`: Physical row 189 Robin
- `ATK% Set / CRIT Rate Set / CRIT DMG Set / Thunder`: Lightning row 56 Ashveil
- `ATK% Set / Eagle / CRIT Rate% Set / Wavestrider`: Wind row 275 Dan Heng
- `ATK% Set / Pioneer / Duke / CRIT Rate% Set / Wavestrider`: Lightning row 220 Moze
- `ATK% Set / SPD% Set / Thunder`: Lightning row 82 Aglaea
- `ATK% Set / Wastelander / Pioneer / CRIT Rate% Set / Wavestrider`: Imaginary row 276 March 7th
- `BE% Set`: Imaginary row 276 March 7th, Imaginary row 84 Rappa, Physical row 162 Boothill
- `BE% Set / SPD% Set`: Fire row 108 Fugue, Fire row 82 The Dahlia, Imaginary row 111 Trailblazer
- `BE% Set / SPD% Set / Passerby`: Fire row 135 Lingsha
- `CRIT Rate% Set / CRIT DMG% Set`: Fire row 56 Sparxie, Physical row 4 Evanescia
- `CRIT Rate% Set / Wavestrider / Quantum% Set / SPD% Set`: Quantum row 111 Tribbie
- `Champion / Scholar / Wavestrider / ATK% Set`: Physical row 216 Argenti
- `Duke + ATK% Set / Thunder / CRIT Rate% Set / Wavestrider`: Lightning row 163 Jing Yuan
- `Quantum% Set / Longevous / CRIT Rate% Set / Wavestrider`: Quantum row 84 Castorice
- `SPD Set + 2-PC: SPD Set`: Imaginary row 246 Welt
- `SPD% Set`: Fire row 270 Trailblazer
- `SPD% Set + 2-PC: SPD% Set`: Lightning row 30 Trailblazer
- `SPD% Set + BE% Set`: Ice row 110 Ruan Mei
- `SPD% Set + Knight / Recluse`: Imaginary row 138 Aventurine
- `SPD% Set + Longevous / Guard / Knight`: Imaginary row 317 Yukong
- `SPD% Set + SPD% Set`: Fire row 162 Jiaoqiu, Fire row 300 Gallagher, Fire row 354 Asta, Ice row 275 Pela, Ice row 4 Cyrene, Ice row 83 Trailblazer
- `SPD% Set + SPD% Set / ATK% Set / Guard / Longevous / Passerby`: Imaginary row 219 Luocha
- `SPD% Set + SPD% Set / Guard / Knight / Recluse`: Ice row 164 Gepard, Ice row 302 March 7th
- `SPD% Set + SPD% Set / Longevous / Guard / Passerby`: Lightning row 190 Bailu
- `SPD% Set + SPD% Set / Longevous Disciple`: Wind row 83 Hyacine
- `SPD% Set + SPD% Set / Passerby`: Physical row 381 Natasha, Quantum row 303 Lynx
- `SPD% Set / ATK% Set`: Physical row 56 Permansor Terrae
- `SPD% Set / ATK% Set / Pioneer`: Fire row 327 Guinaifen

### Unmatched Planar Sets
- `SPD% Set`: Ice row 4 Cyrene

### Unknown Stats
- `(Assuming 4-PC`: Quantum row 84 Castorice stat target
- `DMG`: Quantum row 57 Cipher sphere
- `DMG%`: Quantum row 219 Silver Wolf sphere

### Uninterpreted Lines
- `{"context": "Physical row 56 Permansor Terrae", "text": "Please read the \"Other Notes\" section"}`
- `{"context": "Physical row 216 Argenti", "text": "Battery Build"}`
- `{"context": "Physical row 216 Argenti", "text": "Battery Build"}`
- `{"context": "Fire row 30 Mortenax Blade", "text": "Support Build"}`
- `{"context": "Fire row 30 Mortenax Blade", "text": "Sub DPS Build"}`
- `{"context": "Fire row 30 Mortenax Blade", "text": "Support Build"}`
- `{"context": "Fire row 30 Mortenax Blade", "text": "Sub DPS Build"}`
- `{"context": "Fire row 30 Mortenax Blade", "text": "Support Build"}`
- `{"context": "Fire row 30 Mortenax Blade", "text": "Sub DPS Build"}`
- `{"context": "Imaginary row 246 Welt", "text": "Support Build"}`

### Expanded Trailblazer Matches
- `{"context": "Physical row 270 Trailblazer", "character_ids": ["8001", "8002"]}`
- `{"context": "Fire row 270 Trailblazer", "character_ids": ["8003", "8004"]}`
- `{"context": "Ice row 83 Trailblazer", "character_ids": ["8007", "8008"]}`
- `{"context": "Lightning row 30 Trailblazer", "character_ids": ["8009", "8010"]}`
- `{"context": "Imaginary row 111 Trailblazer", "character_ids": ["8005", "8006"]}`

### Multiple Build Variants
- `{"context": "Imaginary row 276 March 7th", "build_count": 2}`

