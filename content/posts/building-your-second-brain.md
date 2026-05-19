---
title: 'Building your Second Brain'
date: 2026-05-18
author: 'Alex Seward'
summary: 'What happens when you stop writing about personal knowledge management and actually build the thing — with an LLM as the maintenance layer.'
tags:
  - ai
  - data
  - technology
---

In November 2024, I wrote about the idea of a collective second brain — how LLMs were turning our accumulated text into "a living, responsive knowledge pool." I was thinking big: a shared digital twin of human knowledge, a collective memory with a natural language interface.

Now it's time to look at the other end of the telescope.

## The Karpathy Moment

In April 2026, Andrej Karpathy posted a thread about how he'd been using LLMs to build personal knowledge bases. Structured collections of markdown files, maintained by an LLM, browsed in Obsidian. He described a workflow: index source documents into a raw directory, use an LLM to "compile" a wiki of interconnected articles, then query against it. His key insight was almost offhand: "You rarely ever write or edit the wiki manually. It's the domain of the LLM."

## The Ones That Came Before

During my decade at Microsoft, I maintained sprawling OneNote notebooks — one per customer, one per project, tabs breeding tabs, a fractal of good intentions. OneNote was brilliant for capture: meeting notes, architecture diagrams, those half-formed ideas you scribble during a strategy call. But it was terrible for connection. Every notebook was a silo. The insight from a retail transformation sat three notebooks away from the government engagement where it would have been useful, and I'd never find it because OneNote's search was designed for retrieval, not discovery.

I also had previous attempts using Notion and Roam, which somewhat solved the structure problem. Databases, relations, linked views — suddenly I could see patterns across projects. However, Notion demanded something I never had enough of: maintenance time. A personal knowledge base is only as good as the person updating it, and I was always choosing between documenting what I'd learned and doing the next piece of work. The knowledge base slowly went stale, then abandoned, then replaced by the next tool that promised to solve the same problem.

The pattern was always the same: enthusiastic setup, diminishing maintenance, eventual neglect. Not because the tools were bad, but because the bottleneck was human attention. I could capture or I could connect, but I couldn't sustain both.

That's what changed with LLMs. The maintenance bottleneck disappeared.

## What I Actually Built

The vault is built around Obsidian and markdown files. It covers the things I work on, the things I’m learning, and the patterns I keep seeing. It started as a collection of loose markdown files, and is now over 250 interconnected notes — concepts, frameworks, patterns, case studies, source clippings, and research — plus a small set of named workflows that the LLM runs against the vault itself: a curation routine that triages new material, a health check that lints structure, a reading-queue refresh that goes out to the web and brings things back.

The LLM didn't just transcribe what I knew. It drew connections I hadn't made, structured thinking I'd left scattered across years of customer work, and surfaced patterns from my own life that I'd never articulated. When I fed in my blog posts from 2014 to 2025, the system traced four intellectual threads I hadn't consciously identified — an attention critique, a technology-as-augmentation philosophy, a participatory culture thread, and a critical thinking strand — and showed how they converged. 

**The vault isn't a reference library. It's a thinking partner.**

Tiago Forte's Building a Second Brain positioned personal knowledge management as a capture-and-retrieve system. Capture ideas, organise them by actionability (his PARA method), retrieve when needed. That's valuable, but it's fundamentally passive — a filing cabinet with better search. This vault organises by knowledge type, not actionability — and the organiser isn't me.

What Karpathy described, and what I've experienced, is something qualitatively different. The LLM doesn't just file your ideas. It reads across them, finds tensions between your own positions, suggests where your framework for AI governance contradicts your framework for rapid adoption, and asks you to resolve the conflict.

Today, I can open Obsidian and use the Copilot plugin, and ask: `summarise discussions around ROI and Value of AI`. It pulled together direct value, indirect value, strategic value, the J-curve of AI investment, the pilot-to-production gap, the danger of counting generated artefacts as business impact, and the distinction between capacity created and people removed. Pretty sophisticated for a first pass — and grounded in material I had either written, clipped, or verified myself.

That changes the relationship with the wiki. I'm no longer browsing folders, hoping I remember the right note title. I'm asking questions of a body of work that has memory, structure, and context. The system doesn't give me the final answer. It gives me the first map of the territory, quickly enough that I can stay inside the flow of thinking.

**The "linting" is the most valuable part.**

Karpathy mentioned running "health checks" over his wiki — finding inconsistent data, imputing missing information, suggesting new connections. I now run a vault health check as a named skill. It counts files, flags broken links, finds orphans, looks for stale claims, and checks whether each industry sector still has its full set of profile notes. Every run produces genuine insight. Orphaned notes reveal ideas I referenced but never developed. Broken links show where my mental model assumed connections that don't exist on paper. Thin files expose the concepts I think I understand but haven't actually articulated. The structural integrity of the vault is a proxy for the structural integrity of my thinking.

Alongside this, I run a session opener routine that scans the three inbound streams of new knowledge — things I've clipped from the web, things I've recorded as voice notes, things the system has surfaced as worth reading — and presents them as a single "knowledge funnel." Without it, sources pile up and never get integrated. With it, nothing sits unprocessed for more than a session.

**The architecture matters more than the content.**

My collective second brain post imagined a vast shared knowledge pool. What I've learned building a personal one is that the architecture — how you structure the relationships between ideas — matters far more than the volume of content. A thousand unlinked notes is mostly just noise. Two hundred notes with a clear ontology (concepts, frameworks, patterns, case studies, clippings) and dense cross-linking is a knowledge graph that generates new understanding.

This is where Forte's original insight holds: the organisational system matters. However, the organiser is now an LLM, and it can maintain a level of cross-referencing that no human would sustain manually.

## From Collective to Personal to... What?

My 2024 post argued that LLMs were creating a collective second brain. I still think that's true at the macro level.

Karpathy's wiki works because it's *his* research, *his* questions, *his* evolving understanding. My vault works because it's *my* advisory practice, *my* coaching methodology, *my* career's worth of patterns. The LLM is powerful precisely because it operates over a coherent body of individual knowledge — not because it has access to everything.

This might be the real second brain: not a shared pool of all human knowledge, but a personal knowledge architecture, maintained by an LLM, that grows with you. It remembers what you've thought, challenges what you currently think, and suggests what you should think about next.

## The Loop Closes

There's one part of the story I didn't anticipate when I started.

This post was drafted inside the vault. When it's published, it goes live at alexseward.com — and the loop closes.

What I'd missed in the 2024 post was that the natural endpoint of a personal second brain isn't more private knowledge. It's better public output. The vault feeds the blog. The blog gets read, gets criticised, gets referenced — and that comes back into the vault as new clippings, new arguments, new tensions to resolve. The personal architecture and the public one are halves of the same circuit.

And the output doesn't have to be prose. One of the workflows I'm building now turns vault knowledge into small HTML artefacts: interactive explainers, visual maps, dashboards, and decision tools. That matters because some ideas don't want to become essays. A framework might need to be explored, filtered, clicked through, or shown spatially before it makes sense.

This is where the second brain starts to look less like a notebook and more like a workshop. The vault holds the raw material. The LLM helps shape it. The output can be a blog post, a briefing note, a diagram, or a small tool someone else can use.

As Scott Hanselman says, “You have a finite number of keystrokes left in your hands before you die. Rather than answering every email, consider blogging the answer and emailing them the link to your post. Perhaps a knowledge base or wiki would be a better place for your work to live."
