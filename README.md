# Jessica Burnett's CV

**[Read the full CV here →](extended-cv.md)**

I'm a Program Executive for Earth Science Data Systems at NASA Headquarters.
Before that I was a AAAS Science & Technology Policy Fellow at NASA, a
research ecologist at USGS, and a grad student chasing birds in Florida and
Nebraska.

I keep this repo public on purpose. Early in my career I had no idea what a
CV was supposed to look like or how people's careers actually unfolded, so
here's mine, warts and all. That includes the grants I didn't get.

## How this repo works

Everything I've done lives in one place, as data. Each resume is just a
filtered view of that data.

```
data/        ← the running list (single source of truth)
  experience.yml   every role and every accomplishment, tagged
  education.yml  awards.yml  grants.yml  software.yml
  talks.yml  workshops.yml  service.yml  profile.yml
  publications.bib  reports.bib  coursework.csv
templates/   ← one per audience; each picks from data/
  extended-cv.Rmd  everything → extended-cv.md (the page linked above)
  federal.Rmd      USAJOBS format: grade, hours, supervisor, credit hours
  ses.Rmd          Senior Executive Service: organized by ECQ
  industry.Rmd     2 pages, outcomes first
R/cv.R       ← small helper functions the templates use
assets/      ← LaTeX preamble and citation style
build.R      ← renders any or all of the above
```

**Adding something new:** add a bullet to `data/experience.yml` (or the right
file) the week it happens. Give it a `priority` (1 = headline, 2 = strong,
3 = depth) and a few `tags`. If something still needs checking, add a
`verify:` note; templates skip unverified items until the note is removed.

**Making a resume:**

```sh
Rscript build.R extended          # update the public page
Rscript build.R federal           # output/burnett_federal.pdf
Rscript build.R ses industry      # several at once
Rscript build.R all --docx        # everything, plus Word versions
```

Tailored versions for a specific job aren't saved here. Only the current
general version of each template lives in the repo.

**Private details:** phone number, supervisor contact, and mailing address
never go in the repo. Copy `private.example.yml` to `private.yml` (it's
gitignored) and the templates will include them in application versions.

**Requirements:** R with the `rmarkdown`, `knitr`, and `yaml` packages, and a
LaTeX install with XeLaTeX and the Carlito font (for PDFs).

### Tags

`leadership` `people` `governance` `strategy` `efficiency` `budget`
`partnerships` `interagency` `states` `tribes` `private-sector` `policy`
`open-science` `data-systems` `metrics` `grants` `outreach` `mentoring`
`research` `statistics` `software` `conservation` `fire` `field` `teaching`

### Want to copy this?

Go for it. Fork the repo, replace what's in `data/`, and render. Older versions
of my resumes and the original layout are on the
[`archive-2026`](../../tree/archive-2026) branch.
