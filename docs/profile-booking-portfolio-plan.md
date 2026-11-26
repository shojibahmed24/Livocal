
---

## 9. Follow-up: what a professional portfolio actually contains

### 9.1 Save behaviour
The editor is auto-save (450 ms debounce) with a "Saved" tick in the AppBar.
No Save button is needed for fields; dialogs (service, portfolio) save on their
own Save button. Username uses the check icon next to the field.

### 9.2 Username change and old links
Both links used to resolve (old claim kept). Now /u/<old> answers **301** to
/u/<new>, so old links never break and search engines see one canonical URL.

### 9.3 What top freelancer portfolios include
1. Positioning headline (who + outcome), availability + response time.
2. Services with outcome ("Landing page that converts", not "web design").
3. Case studies: client/problem → what I did → measurable result + image.
4. Selected work grid with large previews and live links.
5. Tech stack grouped (Languages / Frameworks / Tools).
6. Testimonials with name, role, company and rating.
7. Experience timeline (role, company, years) or "5+ years" stats.
8. Certifications / education (optional).
9. Social proof numbers (projects shipped, clients, countries).
10. Social links (GitHub, LinkedIn, Behance) + downloadable CV (PDF).
11. FAQ (pricing, process, timezone, revisions).
12. Clear CTA (book a call) repeated after every 2 sections.

### 9.4 Data-model gaps today
Current profile has headline, bio, skills, languages, rate, portfolio links,
services. Missing: case studies, experience, certifications, socials, CV,
FAQ, cover image, response time, projects-shipped stats.

### 9.5 Upgrade phases
- **P-A (1 day):** cover image + response time + social links (GitHub,
  LinkedIn) + stats (projects, years, clients) + CV PDF upload URL.
- **P-B (2 days):** case studies: { title, client, problem, result, image,
  url, tags } rendered as alternating cards; editor dialog.
- **P-C (1 day):** experience timeline + certifications + FAQ (3 items).
- **P-D (1 day):** section ordering, accent colour, print CSS, OG image
  generation from cover.
- **P-E:** public reviews with company/role once review schema captures them.

Approval needed for P-A..P-D. Recommendation: ship P-A then P-B, because a
portfolio without cover/case studies is what the current screenshot shows.
