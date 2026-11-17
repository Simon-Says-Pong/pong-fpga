# Pong on FPGA: Requirements

Source: course brief "Project: Ping Pong game" and grading sheet "BewertungNotenInfo"
(FPGA & VHDL, DHBW, 2026). This document restates them as numbered, testable requirements.
Requirements marked **(derived)** are not in the brief; they are our engineering decisions
needed to meet it. Open points to confirm with the lecturer are listed at the end.

## 1. Deadlines

| What | When |
|---|---|
| Submit presentation (ppt) and project files | end of day **Tue 17.11.2026** |
| Presentation and live demo, slot A (6 groups) | Wed 18.11.2026, 13:00 to 18:00 |
| Presentation and live demo, slot B (5 groups) | Wed 25.11.2026, 13:00 to 18:00 |

## 2. Hardware

| ID | Requirement |
|---|---|
| HW-1 | The design runs on the Digilent Arty board (our board: Arty A7-35T, `xc7a35ticsg324-1L`). |
| HW-2 | Video output goes through a **Digilent Pmod VGA** adapter plugged into two Pmod ports. |
| HW-3 | Output is shown on a monitor with a VGA input, connected by a VGA cable. |
| HW-4 | Players use the on-board push buttons, two per player (the Arty A7 has exactly four: BTN0 to BTN3). **(derived)** |

## 3. Functional requirements (game)

### Playfield and display

| ID | Requirement |
|---|---|
| F-1 | The screen shows two paddles, one at the left edge and one at the right edge, and one ball. |
| F-2 | The current score is displayed at the **top** of the screen. |
| F-3 | Colours are free to choose. (The reference picture uses a red and a blue player, a white ball and a white centre line; this is optional.) |

### Controls

| ID | Requirement |
|---|---|
| F-4 | Each player moves their paddle **up and down** with **two buttons** (one up, one down). |
| F-5 | Paddles stay inside the visible screen area. **(derived)** |

### Game flow

| ID | Requirement |
|---|---|
| F-6 | After power-up / reset the game shows a **welcome screen** (welcome message). |
| F-7 | The game starts when a player presses a button. |
| F-8 | The ball starts in the **centre** of the screen. A 45° start direction is suggested, not mandatory. |
| F-9 | The ball bounces off the top and bottom walls. **(derived)** |
| F-10 | When the ball hits a paddle it is sent back toward the opponent. A 45° rebound is suggested, not mandatory. |
| F-11 | When a player misses the ball, the **opponent scores**. |
| F-12 | After a miss the game **pauses** and a **new ball** is provided (back in the centre). |
| F-13 | Play resumes when a player presses a button. |
| F-14 | At most **6 balls** are played per session. |
| F-15 | After **3 misses per player** the game ends and an **end-of-game message** is shown (see open point Q-1). |
| F-16 | From the end screen a button press or reset returns to the welcome screen. **(derived)** |

### State machine (derived)

```
WELCOME --button--> SERVE --button--> PLAY --miss--> SCORE/PAUSE --(game not over)--> SERVE
                                                         |
                                                         +--(game over)--> GAME_OVER --button/reset--> WELCOME
```

## 4. Technical requirements (derived)

| ID | Requirement |
|---|---|
| T-1 | VGA timing 640×480 @ 60 Hz (pixel clock 25.175 MHz; 25.0 MHz is accepted by practically all monitors). |
| T-2 | The pixel clock is generated from the 100 MHz board clock with the Vivado **Clocking Wizard** (allowed: "simple IP cores, e.g. for clock generation"). |
| T-3 | Button inputs are synchronised (2 flip-flops) and debounced before use. |
| T-4 | Game logic (ball and paddle positions) updates once per frame (on vsync or a frame tick), not per pixel. |
| T-5 | Text (welcome, game over) and score digits are drawn from a **self-made** character/digit ROM. Do not copy font tables from the internet (see R-3). |
| T-6 | Sizes, speeds, colours and the game-over rule are VHDL `generic`s/constants so they can be changed in one place. |
| T-7 | The design meets timing (no negative slack) and has a `create_clock` constraint for the board clock. |

## 5. Organisation and rules

| ID | Rule |
|---|---|
| R-1 | Groups of at most 3 people. |
| R-2 | Each group member must present what **they personally** built, so module ownership must be clear. |
| R-3 | **No code may be copied from the internet.** Everything is written by the group. |
| R-4 | Time per group: 30 min, i.e. 15 min presentation, 10 min demo on the board, 5 min questions. |
| R-5 | Deliverables: presentation file (ppt) and the project (Vivado sources), submitted by 17.11.2026. |

## 6. Grading (100 points)

| Area | Criterion | Points |
|---|---|---|
| **VHDL code and functionality (60)** | Functionality: all required functions and specifications correctly implemented | 0 to 50 |
| | Code quality: readability, comments, efficiency, VHDL conventions | 0 to 10 |
| **Presentation (20)** | Structure, documentation and content: logical flow, clear explanations | 0 to 10 |
| | Delivery: time management, speaking freely, understandability | 0 to 10 |
| **Questions and defence (20)** | Depth of understanding, correct answers to technical questions, ability to justify design decisions | 0 to 20 |

Grade scale: 95 to 100 points = 1.0, then one grade step (1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0) per
5 points, so 50 to 54 points = 4.0 (pass); below 50 points = 5.0 (fail).

Takeaway: half the grade is the game working on the board. A further 30 points depend on
each member being able to explain and justify their own design decisions.

## 7. Suggested module split (derived)

| Module | Content | Owner |
|---|---|---|
| `clk_gen` | Clocking Wizard instance, 100 MHz to 25 MHz | |
| `vga_sync` | hsync/vsync, pixel x/y counters, video-on | |
| `btn_debounce` | synchroniser + debouncer, per button | |
| `game_fsm` | WELCOME / SERVE / PLAY / PAUSE / GAME_OVER, score and miss counters | |
| `ball_paddle` | positions, movement, collisions | |
| `renderer` | draws paddles, ball, centre line, score, text into RGB | |
| `char_rom` | own digit and letter bitmaps | |
| `top` | wiring, pin constraints | |

## 8. Open points to clarify with the lecturer

- **Q-1, end condition.** "Max 6 balls" and "after 3 misses by each player the game ends" can be read two ways:
  (a) the game ends as soon as **one** player has missed 3 times (then at most 5 balls are ever played), or
  (b) exactly 6 balls are played and the game ends after the 6th ball (only 3:3 means "3 misses each").
  Until clarified, make the rule a generic so both work.
- **Q-2, score display.** Show points (opponent's misses) or misses? We plan to show points per player.
- **Q-3, group size.** "3 persons maximum per group and two groups of 2 persons": confirm our group size.
- **Q-4, submission channel.** Moodle upload or something else, and in which format (zip of the Vivado project, or sources only)?
- **Q-5, AI tools.** The brief only forbids copying code from the internet. It does not mention AI assistants; ask before relying on them.
