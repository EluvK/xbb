---
name: design-new-feature
description: Design a new feature for the XBB app, including data models, local DB, sync engine, and UI components.
---

We need to follow these steps to design a new feature for the XBB app:

# Step 1: Define the feature and summarize a details design doc

Interview me relentlessly about every aspect of what we are designing until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

As a result, you may at least resolve these but not limited to these:
- What the name(code name and user-facing name) and description of the feature?
- What are the most common user cases
- What are the data models needed for this feature, must be designed with syncstore annotation for codegen.
- Are this feature all-platform or platform-specific? If platform-specific, which platform(s) and why?
- Are the data synced to server or local only?
- What are the UI components needed for this feature? Sketch the UI layout and interactions.

To deliver the final design doc in a markdown file.

# Step 2: Figure out the implementation plan

Break down the implementation into small tasks, and for each task, provide a detailed implementation plan, including which files to edit/create, which data models to define, which UI components to build, and how to test.

Put it after the design doc.
