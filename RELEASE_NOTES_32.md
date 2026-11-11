# Fort 32 â€” A new sky

Everyone must run **Fort 32**. Saves load unchanged. This release changes how the sky and the daylight look; rules and balance are the same as Fort 31.

## What is new

- **Real sunrises and sunsets.** The sun now rises low in the east, climbs to noon and sinks low in the west, so shadows are long at both ends of the day. Around dawn and dusk the sky burns orange about the sun, with a rose belt opposite it and violet overhead.
- **Clouds that take the light.** Two cloud decks are lit from the sun's side with bright edges, turn gold and rose at sunset and dark under the moon. Thin cirrus streaks sit high above them.
- **A deeper day sky.** Deep blue overhead, pale and hazy at the horizon, with a soft corona round the sun.
- **A night worth looking at.**
  - A large moon with seas, craters and a phase, crossing the sky during the night.
  - A small teal second moon in the north-west.
  - Stars in three sizes and several colours that twinkle and slowly wheel overhead.
  - The Milky Way as a band of dust and faint stars.
  - A shooting star every few seconds.
  - An aurora in the northern sky: green, blue and violet curtains that ripple.
- **A clearer sky.** Scene fog no longer covers the sky, which is what used to flatten the clouds and hide the stars. The distance still fades into haze on the ground.

## Performance

Frame rates are unchanged from Fort 31 on the development PC (for example 208 fps from the keep at hearth 1 and 81 fps with 100 raiders at night).

## Known limits

- The aurora is always in the north and appears every night; it is not tied to biome or weather.
- There is no weather: no rain, snow or overcast days.
- Water and the terrain do not reflect the new sky's colours beyond the existing light and ambient tint.

## Checks

- `tests/sky32_review.gd` renders eight reference views (noon, dawn, dusk, night) to `build/sky32_*.png`.
- All 43 headless suites pass, and a four-player run passes on both the development and packaged builds.
