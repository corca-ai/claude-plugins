# The Essence of the Essence

> Source: <https://essenceofsoftware.com/posts/distillation/>

This article summarizes the key ideas in the book *The Essence of Software*. It is not intended to be understandable by itself. It gives almost no examples, makes claims without justifying them, and cites almost no related work. And it's not nearly so much fun to read as the book :-). But, hey, at least it's short(ish)!

If you haven't read the book, I recommend that you don't start with this, but watch my [ACM talk](/posts/acm-tech-talk/) instead. But perhaps you don't really want to read the book, and just want to be able to hold your own at a cocktail party showing off your sophistication in software design. In that case, this may be for you.

If you've read the book, this summary should be a useful reminder of the key ideas, to help you solidify them in your mind and relate them to other approaches. In this sense, it augments the shorter list of provocative questions in Chapter 12 of the book.

A final warning before you jump in: this summary assumes a fairly extensive background in software design and development. The book itself is aimed at a broader audience, introduces the ideas more gently by way of example, and relegates the harder technical stuff to end notes.

## Defining Software Design

In most fields, "design" means shaping an artifact to meet the needs of users, thus sitting at the boundary between humans and machines. Despite Kapor's notable manifesto in 1990, and the book edited by Winograd that followed in 1996, little attention has been paid to software design.

Enormous effort, in contrast, has been devoted to software engineering (whose interest instead is software's internal structure and means of construction). This disparity of attention has resulted in great advances in programming, represented by a major body of knowledge and well-known design principles.

The field of human-computer interaction has likewise produced an impressive body of knowledge about user interfaces and how they shape the way we understand and use software. But for software design, where the focus is on the fundamental abstractions that underlie both the interface and the implementation, our knowledge is much more limited, and we have had to be content with being guided instead by vaguer notions, and (albeit sensible) appeals to simplicity and clarity.

## The Book's Aims and Approach

The aims of the book are to highlight a central aspect of software design; to lay out a way to structure and express software designs from this perspective; to provide some heuristics and principles for design; and, more generally, to inspire a renewed focus on software design as a discipline.

The book is driven by examples drawn from over 100 apps. By focusing on widely used software produced by the best companies, it seeks to show that serious problems are rife, and challenge even the most talented developers, and that the book's ideas and techniques apply to real software.

The book presents a design approach comprising simple textual and diagrammatic notations, a collection of readily applicable heuristics, and some deeper principles. In order to explain the approach in more detail, and to show how it differs from many prior approaches, a collection of end notes is included covering topics from design thinking to formal methods.

## The Problem

Software is harder to use than it needs to be. We spend an increasing portion of our lives engaged with software apps and systems, so improving the design of software impacts the quality of our lives and our ease of working effectively together.

As software becomes an ever more critical part of our civic infrastructure, we rely on apps and systems to behave predictably and reliably. A high proportion of failures are due to user errors, for which poor design is usually to blame. And even when a failure is attributed to a bug in the code, it is likely that the bug is due to lack of clarity in design (rather than a simple failure to meet a specification).

Lack of clarity in software design also makes software harder to build, and leads to degradation over time as accretions to a codebase compromise its modularity yet further.

## Levels of Design

Software design activities and criteria can be assigned to three levels: **physical**, which concerns the choice of colors, type, layout, etc, and is influenced by particular human anatomical and cognitive capabilities; **linguistic**, which concerns the use of icons and labels, terminology, etc, and is dependent on shared cultural and linguistic assumptions; and **conceptual**, which concerns the underlying semantics of the application, including the actions that can be performed and the effects they have, and the structure and interpretation of the state as viewed by the user.

The conceptual level is the most fundamental; different physical and linguistic designs for an app might be equally effective, but even small changes to the conceptual design are usually very disruptive to users. Users' problems with apps arise more often from incorrect conceptual understandings than from an inability to interpret the physical and linguistic signals of the user interface.

## Prior Work on Conceptual Design

The importance of the conceptual level has been recognized for more than half a century. From early on, researchers noted the importance of a user's "mental model", and the need for the design to construct such a model explicitly, so that the user's model and the system model coincide. Fred Brooks coined the term "conceptual integrity" and argued that the conceptual aspects of software design represented the essence of the field, as opposed to the accidental aspects, to which he relegated the concerns of "representation." The fields of conceptual modeling, domain modeling and formal methods all emphasized the centrality of an abstract model of state (and, in the case of formal methods, also behavior) in the design of software.

And yet none of these fields expressly addressed the problem of designing the conceptual structure of software in order to meet the needs of the user and to align the user's understanding. Formal methods focused primarily on the problem of correctness, and ensuring conformance of the implementation to the model. Conceptual modeling and domain modeling focused primarily on the representation of knowledge about the context of operation of a system, rather than on the structures that the designer invented.

Most curiously missing was a well defined notion of "concept." Even in the field of conceptual modeling, there is no shared understanding of what a concept might be, or even well-known candidate definitions. An entire conceptual model seems to be too large to count as a single concept, and its constituent entities (or classes or objects) are too small, especially since an informal understanding of a concept tends to involve relationships amongst multiple elements.

## A New Definition of Concept

A concept is a reusable unit of user-facing functionality that serves a well-defined and intelligible purpose. Each concept maintains its own state, and interacts with the user (and with other concepts) through atomic actions. Some actions are performed by users; others are output actions that occur spontaneously under the control of the concept.

A concept typically involves objects of several different kinds, holding relationships between them in its state. For example, the Upvote concept, whose purpose is to rank items by popularity, maintains a relationship between the items and the users who have approved or disapproved of them. The state of a concept must be sufficiently rich to support the concept's behavior; if Upvote lacked information about users, for example, it would not be able to prevent double voting. But the concept state should be no richer than it need be: Upvote would not include anything about a user beyond the user's identity, since the user's name (for example) plays no role in the concept's behavior.

## Concept Reuse and Familiarity

Most concepts are reusable across applications; thus the same Upvote concept appears for upvoting comments in the New York Times and for upvoting answers on Stack Overflow. A concept can also be instantiated multiple times within the same application.

This archetypal nature of concepts is essential. From the user's perspective, it gives the familiarity that makes concepts easy to understand: a user encountering the same context in a new setting brings their understanding of that concept from their experience in previous settings.

From a designer's perspective, it allows concepts to be repositories of design knowledge and experience. When a developer implements Upvote, even if they can't reuse the code of a prior implementation, they can rely on all the discoveries and refinements previously made. The community of designers could develop "concept catalogs" that capture all this knowledge, along with relationships between concepts.

## Concept Independence

Perhaps the most significant distinguishing feature of concepts, in comparison to other modularity schemes, is their mutual independence. Each concept is defined without reference to any other concepts, and can be understood in isolation.

Early work on mental models established the principle that, in a robust model, the different elements must be independently understandable. The same holds in software: the reason a user can make sense of a new social media app, for example, is that each of the concepts (Post, Comment, Upvote, Friend, etc) are not only familiar but also separable, so that understanding one doesn't require understanding another.

Concept independence lets design scale, because individual concepts can be worked on by different designers or design teams, and brought together later. Reuse requires independence too, because coupling between concepts would prevent a concept from being adopted without also including the concepts it depends on.

Polymorphism is key to independence: the designer of a concept should strive to make the concept as free as possible of any assumptions about the content and interpretation of objects passed as action arguments.

## A Structure for Describing Concepts

To work with concepts, we need a simple structure for describing them. A concept is defined by its behavior, which comprises its state space and a set of actions. These can be defined using standard methods and notations.

For defining the state space, a data model is given that consists of a collection of components, each of which is a scalar/option, set or relation (of any arity). This model can be recorded with textual declarations or as an extended entity-relationship diagram.

Actions can be initiated by the user or by the system, and a single action can have both inputs and outputs. A single action can abstract what would be an entire use case in object-oriented modeling approaches, allowing a much terser form of description.

From a data modeling perspective, there is no global data model. Instead, there is a collection of local data models, one for each concept. Each concept's data model is just rich enough to support its actions.

The definition of a concept augments this basic behavioral description with two more novel parts: the purpose and the operational principle.

## Concept Purposes

The idea that an artifact should have a purpose distinct from its specification is hardly novel. What is novel in concept design is the idea that it is not sufficient for the system or app as a whole to have a purpose. Each concept in its design should have its *own* purpose. A concept's purpose defines, in a general setting, the reason for its invention and what benefits it offers; in the setting of a particular app, it defines the motivation and justification for including the concept.

Purposes also clarify subtle distinctions between related concepts. In social media, for example, there are several concepts that may sit behind a "thumbs up" widget: Upvote (rank items by popularity), Reaction (convey emotional reaction), Recommendation (learn user preferences), and Profile (track interests for advertising).

## The Operational Principle

A concept definition also includes its *operational principle* (OP), an archetypal scenario that shows how the concept fulfills its purpose.

Superficially, the OP is like a use case, but it plays a very different role. Use cases are a specification notation, and a full spec typically requires many use cases. Since a concept's actions fully define its behavior, nothing more is needed to predict how the concept will behave.

Instead, the OP captures the dynamic essence of the concept, telling the most basic story about how the concept works. Sometimes the OP is so simple it barely even needs stating: when you add a comment to a post, your comment will subsequently appear along with the post (the OP of the Comment concept). But often the OP is more interesting:

- **Trash**: when you delete an item, you can restore it from the trash; once you empty the trash, it's gone forever and its space is reclaimed.
- **Style**: if you assign a style to two items, and then you update the style, both items will be updated in concert.
- **Upvote**: after users have upvoted items, the items will be ranked by the number of times they were upvoted.

The OP may also be aspirational, applying only in ideal circumstances. The OP often provides the clearest way to explain a concept. Paradoxically a full behavioral description is often less helpful, since it fails to distinguish the essential aspects of the concept design from more arbitrary design decisions.

## Concept Synchronization

Within an app, concepts can operate largely without interaction. But often concepts need to be coupled together to achieve the app's goals. For example, the upvote action of the Upvote concept could be synchronized with the edit action of the Post concept, to prevent edits after a post has been upvoted.

Synchronizations are defined reactively: when an action occurs in one concept, some actions should occur in other concepts. Each synchronization is atomic and happens in its entirety or not at all.

This model of communication and interaction is inspired by Hoare's CSP. A crucial property: the behavior of each individual concept is preserved. Synchronization can prevent a concept from executing an action, but it can never cause an action to occur that would not be possible for the concept in isolation. Composing concepts maintains their *integrity*.

## Synchronization and Automation

Synchronization of concepts is often a form of automation. Omission of a desirable automation can be attributed to *under-synchronization*: in Zoom, for example, raised hands might be automatically lowered after a participant has their turn.

Automation preempts manual control and thus can be problematic — *over-synchronization*: in some calendar apps, deleting an event leads undesirably to declining the invitation.

## Synchronization and Decomposition

What an app presents as a single concept may be better understood as a synchronization of multiple component concepts. Facebook's 'like' is a synchronization of Upvote, Recommendation, Reaction and Profile — responsible for confusions like an 'angry' reaction producing a positive upvote.

## Concept Synergy

In some designs, concepts can take advantage of each other so that one concept achieves its own functionality in part by relying on another. Apple's synergistic composition of the Folder and Trash concepts: by making the trash a folder, the design allows the action of moving items between folders to be used to restore items from the trash.

## Concept Dependence Diagrams

A concept C1 depends on concept C2 in an app A when the inclusion of C1 only makes sense if C2 is also present. Dependencies determine intelligible orders of explanation, define application families, and suggest development order.

## Concept Mapping

In an implementation, concepts must be mapped to the user interface, connecting the conceptual level to the physical and linguistic levels. Some concepts present tricky mapping challenges, and good mappings can be part of the design knowledge associated with a concept.

## Concept Design Principles

**Familiarity**. When possible, a familiar concept should be preferred to a new, unfamiliar one. The familiarity principle can be seen as an application of a meta principle of consistency.

**Specificity**. Purposes and the concepts that fulfill them should be in one-to-one correspondence. This implies no *redundancy* (each purpose fulfilled by at most one concept) and no *overloading* (each concept serves at most one purpose). Related to the *independence axiom* in Nam Suh's theory of mechanical design.

**Integrity**. When concepts are put together into an app, each concept should continue to behave according to its (app-independent) concept definition. If concepts are composed by synchronization, integrity will be preserved by design.

## Comparisons to Other Approaches

Concept design builds on more than 50 years of advances. The article compares to: *Concept maps*, *Concept lattices*, *Conceptual modeling*, *Objects and classes*, *Domain-driven design* (DDD proposes bounded contexts; concept design proposes finer-grained modularity within an app), *Feature-oriented development*, *Cross-object modularity mechanisms* (AOP, subject-oriented, role-based programming), *Feature interaction*, and *Microservices* (a concept is like a "nanoservice" — more limited scope, single focused purpose, and reusable across apps).
