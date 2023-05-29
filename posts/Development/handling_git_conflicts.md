---
date: 2022-09-20
title: Solving Merge Conflicts
---

As I heard once, now I think handling merge conlficts is one of the most critical
parts of a project. If you don't do it extremely carefully, you will end up
messing something up and having to *redo* the conflict solving or waste some
nice time figuring out what did you do wrong when merging.

So it's really worth it to invest some extra time by paying attention and
double-checking what you're doing the merging branches with conflicts.

**git-imerge** e*merges* to solve that problem by providing an incremental way of
merging:

- Start a merge with `git-imerge merge <branch>`
- It will merge commits until conflicts arise, then solve the conflicts and run `git-imerge continue`
- Follow this loop until the program says the merge is complete, then run `git-imerge finish`

In my experience using it, it makes merging a bit slower, sometimes you end up
fixing almost the same commits but the overall experience is very incremental
and smooth.
