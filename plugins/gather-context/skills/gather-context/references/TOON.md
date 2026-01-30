# TOON Format & Transformation

## Format

```toon
rows[3]{Name,Score,Comment}:
  Alice,"95",Great work!
  Bob,"87","Good effort\nKeep improving"
  Charlie,"92","Well done, excellent!"
```

## Transformation

Survey/session format (first column(s) = questions/labels, header = people) → transform to Markdown:

**Single label column:**
```toon
rows[2]{"",Person1,Person2}:
  Satisfaction,"9","7"
  Reason,Great session,Needs improvement
```
```markdown
## Satisfaction
- **Person1**: 9
- **Person2**: 7

## Reason
- **Person1**: Great session
- **Person2**: Needs improvement
```

**Multiple label columns:**
```toon
rows[3]{"","",Person1,Person2}:
  Satisfaction,Score,"9","7"
  "",Reason,Great session,Needs improvement
  Improvement,Suggestion,More examples,Shorter sessions
```
```markdown
## Satisfaction
### Score
- **Person1**: 9
- **Person2**: 7

### Reason
- **Person1**: Great session
- **Person2**: Needs improvement

## Improvement
### Suggestion
- **Person1**: More examples
- **Person2**: Shorter sessions
```

Hierarchical labels (empty cells inherit from above):
```
MainTopic,,Person1,Person2
,SubTopic,Opinion1,Opinion2
,,Opinion3,
```
→ Transform to MainTopic > SubTopic > per-person responses structure

## Spec

Refer to [TOON spec](https://github.com/toon-format/toon) when needed.
