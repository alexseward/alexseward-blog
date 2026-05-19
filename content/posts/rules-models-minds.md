---
title: 'Rules, Models, Minds'
date: 2026-04-22
author: 'Alex Seward'
summary: 'Every process step is a Rule, a Model, or a Mind. Map all three before you automate anything. A diagnostic tool for AI system design.'
sectionLabel: 'Technology'
tags:
  - ai
  - architecture
---

Every step in any process requires one of three types of intelligence.

### 1. Rules (Deterministic)

- **What it is:** Logic. `IF/THEN`. Math. Same input, same output, every time.
- **The Trap:** Using a language model to check if `2+2=4`. It doesn't make your system "smarter." It makes it unpredictable, slow, and expensive.
- **The Rule:** If a simple script can do it perfectly, do not use AI.

### 2. Models (Probabilistic)

- **What it is:** Pattern recognition. Summarization, classification, prediction.
- **The Trap:** Treating a guess as a fact. A model's output is a high-probability suggestion, not ground truth.
- **The Rule:** Validate everything. Check the confidence. Structure the output. Plan for when the model is wrong.

### 3. Minds (Human)

- **What it is:** Accountability. Judgment, empathy, ethics, and owning the consequences.
- **The Trap:** Automating a decision you can't explain to your boss, your customer, or a regulator.
- **The Rule:** A model can _support_ a high-stakes decision. It cannot _own_ it. Someone has to be responsible.

## Your Sanity Check

Next time you're in a meeting about an AI agent, ask these questions. If the team doesn't have good answers, you have a problem.

1. **"Which steps here are just Rules?"**  
    Force the team to find the simple logic first. This will slash your budget and increase stability.
    
2. **"What happens when the Model is only 40% confident?"**  
    If there's no fallback path to a Rule or an escalation to a Mind, the design is too fragile.
    
3. **"How do we validate the Model's output before the next step runs?"**  
    If the answer is "we trust it," they are building on sand. You need a validation layer—another Rule—to protect the rest of the system.
    
4. **"Who owns the outcome when this makes a mistake?"**  
    This question uncovers which steps truly belong in the "Minds" zone. If no one can answer, you are automating accountability away. That never ends well.
    

## The Goal Isn't Full Automation

The boundaries between these zones will shift. As models improve, some "Mind" tasks will become "Model" tasks. That's fine.

This isn't a static map. It's a diagnostic tool.

The goal isn't to remove humans from the loop. It's to use them for the one thing AI can't do: take responsibility.

Stop building agents.

Start building systems.
