---
title: 'Tiny Tools with Codex'
date: 2026-06-30
author: 'Alex Seward'
summary: 'How I used Codex to build two one-user tools: a meal planner around local food deliveries and a safe Raspberry Pi and Plex workflow for a 55,000-track music library.'
aliases:
  - /posts/building-tiny-tools-with-codex/
sectionLabel: 'Technology'
tags:
  - ai
  - tools
  - codex
  - domestic-systems
  - music
  - technology
---

I have recently used Codex to build two small tools for myself: a meal-planning app and a set of scripts for running and maintaining my music library on a Raspberry Pi.

They solve unrelated problems, but they have one thing in common: neither needs to work for anyone else. [Tiny Tool Town](https://www.tinytooltown.com/) describes this kind of software as being "made for an audience of one". Coding agents such as Codex make that a much more practical proposition.

## Meal Prep

For years, HelloFresh worked well for me. I was often cooking for one around unpredictable travel and long working days. Its value was not only the correctly portioned ingredients; it was having a set of structured recipes and not needing to decide what to cook each evening.

I deliberately moved away from it to buy meat from a local butcher and get fruit and vegetables through Oddbox deliveries. I preferred that way of sourcing food, but I found that I missed the structure around the ingredients. I had good food arriving on different schedules without an equally reliable way to turn it into a workable week of meals.

Using Codex, I built a local browser app around that specific routine. It keeps a simple inventory of fresh, frozen and incoming ingredients, alongside pantry staples. It has a stable library of around 30 numbered dinners and scores them against the ingredients currently available.

The weekly plan normally contains four of those dinners and, when there is a good match, one trial from a cookbook I already own. This leaves two nights for leftovers, eating out or something low effort. The Sunday workflow confirms the current inventory before producing a one-page schedule with the ingredients allocated to each meal, anything that needs using early, and pantry extras to check.

## Alex-Pi

My second use case was a replacement for the [Plex media server I previously ran on Azure](https://gist.github.com/alexseward/dfe9f71ce3d4896dd245734f6c0c1c6b).

Spotify is still the easiest way to play most music, but I also have more than 55,000 songs collected over roughly twenty years. Many are vinyl rips, lost media or tracks that are simply not available on streaming services. Instead of continuing with the Azure setup, I repurposed an old hard drive and a Raspberry Pi, and created a Telegram-based bot for controlling it; all built in collaboration with Codex.

The Music app on my Mac is the source of truth, while the drive attached to the Pi used by Plex is a mirror. The sync runs as a dry-run by default and creates reports showing files that need to be copied or updated, along with anything that exists only on the Plex drive. When I apply the plan, new and changed files are copied and destination-only files are moved into a dated quarantine folder rather than deleted. There is also a smaller workflow for syncing only recently imported albums.

Codex was useful here because the work involved more than writing one script. It helped inspect an old library with inconsistent metadata and duplicate folders, define the source-of-truth rule, build cautious tools around it, and document a repeatable routine.

## The Audience of One

Neither project is a product. The meal planner is built around one person's deliveries, cookbooks and weekly routine. Alex-Pi is built around one music collection, one storage layout and one home server.

That specificity used to make small software difficult to justify. Even a simple tool required enough development time that it either needed a wider market or remained a spreadsheet, a manual process or an unfinished idea. Apps like Codex reduce that cost enough to make software for one user worthwhile.

That is the tiny-tool revolution I find interesting: not more generic apps, but more people able to build small, inspectable tools around the way they already live and work. A useful piece of software no longer needs a market larger than its maker.
