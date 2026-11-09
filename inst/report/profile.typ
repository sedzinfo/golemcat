// The Big Five profile report of golemcat.
// Static template: report_pdf() writes the data (results.csv) and passes the rest with
// --input, so this file never changes from one person to the next.

#let rows = csv(sys.inputs.at("data", default: "results.csv"), row-type: dictionary)
#let date = sys.inputs.at("date", default: "")
#let answered = sys.inputs.at("answered", default: "")
#let total = sys.inputs.at("total", default: "")

// palette ------------------------------------------------------------------------------
#let ink = rgb("#1d2433")
#let muted = rgb("#667085")
#let hairline = rgb("#e4e7ec")
#let track = rgb("#eef1f5")
#let navy = rgb("#16224a")
#let trait-colors = (
  Openness: rgb("#6d4aff"),
  Conscientiousness: rgb("#0e8a7d"),
  Extraversion: rgb("#e8772e"),
  Agreeableness: rgb("#d6427a"),
  Neuroticism: rgb("#2f6fdf"),
)
#let col(scale) = trait-colors.at(scale, default: navy)

// page -----------------------------------------------------------------------------------
#set document(title: "Your Big Five profile")
#set text(font: "Manrope", size: 9.5pt, fill: ink, lang: "en")
#set par(leading: 0.68em, spacing: 1.05em, justify: false)
#set page(
  paper: "a4",
  margin: (x: 2cm, top: 2cm, bottom: 2.1cm),
  background: context if here().page() == 1 {
    place(top, rect(width: 100%, height: 8.2cm, fill: gradient.linear(navy, rgb("#2b3f8f"), angle: 20deg)))
    // a soft row of the five trait colours along the foot of the band
    place(top, dy: 8.2cm, grid(
      columns: (1fr,) * 5,
      ..trait-colors.values().map(c => rect(width: 100%, height: 3pt, fill: c)),
    ))
  },
  footer: context if here().page() > 1 {
    set text(size: 7.5pt, fill: muted)
    line(length: 100%, stroke: 0.5pt + hairline)
    v(-4pt)
    grid(
      columns: (1fr, auto),
      [Big Five profile #h(4pt) · #h(4pt) #date],
      counter(page).display("1 of 1", both: true),
    )
  },
)
#show heading.where(level: 1): it => {
  set text(size: 17pt, weight: "bold", fill: navy)
  block(above: 0pt, below: 10pt, it.body)
}
#show heading.where(level: 2): it => {
  set text(size: 11pt, weight: "bold", fill: navy)
  block(above: 16pt, below: 7pt, it.body)
}

// building blocks --------------------------------------------------------------------------
#let num(x) = float(x)
#let pct-label(x) = str(calc.round(num(x))) + "%"

// a 0-100 track: the shaded likely range, the middle line and the score as a dot
#let scale-bar(row, height: 12pt) = {
  let c = col(row.scale)
  let p = num(row.pct)
  let lo = num(row.lo)
  let hi = num(row.hi)
  block(width: 100%, height: height, {
    place(horizon, rect(width: 100%, height: height * 0.55, radius: height, fill: track))
    place(horizon, dx: lo * 1%, rect(width: (hi - lo) * 1%, height: height * 0.55, radius: height, fill: c.lighten(72%)))
    place(horizon, dx: 50%, line(angle: 90deg, length: height + 4pt, start: (0pt, -2pt), stroke: 0.9pt + muted.lighten(30%)))
    place(horizon, dx: p * 1% - height / 2, circle(radius: height / 2, fill: c, stroke: 2pt + white))
  })
}

#let ends(low, high) = grid(
  columns: (1fr, 1fr),
  text(size: 7.8pt, fill: muted, low),
  align(right, text(size: 7.8pt, fill: muted, high)),
)

// cover ----------------------------------------------------------------------------------
#block(height: 5.4cm, width: 100%, inset: (top: 2pt), {
  set text(fill: white)
  text(size: 8.5pt, weight: "semibold", tracking: 1.4pt, fill: white.transparentize(25%))[PERSONALITY PROFILE]
  v(6pt)
  text(size: 30pt, weight: "extrabold")[Your Big Five profile]
  v(2pt)
  text(size: 11pt, fill: white.transparentize(15%))[The five broad traits of personality, measured with an adaptive test]
  place(bottom + left, grid(
    columns: (auto, auto, auto),
    column-gutter: 28pt,
    ..(
      ("Date", date),
      ("Statements answered", answered + " of " + total),
      ("Traits", str(rows.len())),
    ).map(((k, v)) => stack(
      spacing: 4pt,
      text(size: 7.5pt, weight: "semibold", tracking: 0.8pt, fill: white.transparentize(35%), upper(k)),
      text(size: 11pt, weight: "bold", v),
    )),
  ))
})

#v(1.9cm)

= At a glance
Each line shows where your score falls among about 20,000 people who took the same
questionnaire. The *dot* is your score, the *shaded band* is the range your true score most
likely lies in, and the *thin line* marks the middle, where half of people score lower and
half higher.

#v(6pt)
#block(
  width: 100%,
  inset: (x: 14pt, y: 12pt),
  radius: 8pt,
  stroke: 0.6pt + hairline,
  {
    let label-row(..xs) = grid(
      columns: (3.6cm, 1fr, 1.3cm),
      column-gutter: 10pt,
      ..xs,
    )
    for (i, row) in rows.enumerate() {
      if i > 0 { v(9pt) }
      label-row(
        align(horizon, text(weight: "bold", row.scale)),
        align(horizon, scale-bar(row)),
        align(horizon + right, text(size: 12pt, weight: "extrabold", fill: col(row.scale), pct-label(row.pct))),
      )
    }
    v(6pt)
    label-row(
      [],
      text(size: 7.3pt, fill: muted, grid(
        columns: (1fr, 1fr, 1fr),
        [lower], align(center)[middle], align(right)[higher],
      )),
      [],
    )
  },
)

#v(10pt)
#block(
  width: 100%,
  inset: 12pt,
  radius: 8pt,
  fill: rgb("#f5f7fb"),
  text(size: 8.8pt)[
    *Personality traits are neither good nor bad.* A high or a low score only says which way
    you tend to lean compared with other people, and each end of a trait has its own
    strengths. This is not a clinical or diagnostic test, and it is best read as a starting
    point for reflection.
  ],
)

// traits ---------------------------------------------------------------------------------
#pagebreak()
= Your five traits
#v(4pt)
#for row in rows {
  let c = col(row.scale)
  block(
    breakable: false,
    width: 100%,
    above: 0pt,
    below: 18pt,
    stroke: (left: 3.5pt + c),
    inset: (left: 14pt, y: 4pt),
    {
      grid(
        columns: (1fr, auto),
        align: bottom,
        stack(
          spacing: 5pt,
          text(size: 13pt, weight: "bold", fill: navy, row.scale),
          text(size: 8.6pt, fill: muted, row.about),
        ),
        text(size: 22pt, weight: "extrabold", fill: c, pct-label(row.pct)),
      )
      v(7pt)
      scale-bar(row)
      v(2pt)
      ends(row.low, row.high)
      v(5pt)
      text(size: 9pt)[Your score is #row.sentence. #row.reading]
    },
  )
}

// method ---------------------------------------------------------------------------------
#pagebreak()
= How your scores are calculated

== 1. From your answers to a trait level
Every statement was calibrated on about 20,000 people with a statistical model, the rating
scale model. For each statement the model tells how likely people at each level of a trait
are to choose each answer. The test starts by assuming you are at the average level. After
every answer it works out which levels best fit all your answers so far, and takes the
average of those levels as your score. It then shows you the statement that can tell it the
most about you, and it moves on from a trait as soon as the score is precise enough.

== 2. From a trait level to a standard score
In the comparison group the average level of each trait is set to 0. Your level is divided
by how widely the comparison group is spread on that trait, its standard deviation. The
result is a standard score: 0 is exactly average, +1 is one standard deviation above average
and −1 is one below.

== 3. From a standard score to a percentage
Traits like these are assumed to follow a bell curve, the normal distribution. The
percentage is the share of the bell curve below your standard score: a score of 0 gives 50%,
+1 gives about 84% and −1 about 16%.

== Your numbers
#v(2pt)
#{
  set text(size: 8.6pt)
  let head(x) = text(size: 7.4pt, weight: "bold", fill: muted, upper(x))
  table(
    columns: (1fr, auto, auto, auto, auto, auto),
    align: (left, right, right, right, right, right),
    stroke: (x, y) => if y == 0 { (bottom: 0.8pt + navy) } else { (bottom: 0.5pt + hairline) },
    inset: (x: 6pt, y: 6.5pt),
    table.header(
      head[Trait], head[Statements], head[Spread (SD)], head[Standard score], head[Percentage], head[Likely range],
    ),
    ..rows.map(row => (
      box(circle(radius: 3pt, fill: col(row.scale))) + h(5pt) + text(weight: "semibold", row.scale),
      row.answered + " of " + row.total,
      row.sd,
      row.z,
      text(weight: "bold", pct-label(row.pct)),
      pct-label(row.lo) + " to " + pct-label(row.hi),
    )).flatten(),
  )
}

== Good to know
#set list(marker: text(fill: navy, sym.bullet), spacing: 0.9em)
- *Every score has some uncertainty.* The likely range is the percentage one standard error
  either side of your score: about two times out of three, your true percentage lies in it.
- *With only a few answers, scores are drawn a little towards the middle,* because the test
  starts from the average and needs evidence to move away from it.
- *The percentages come from the bell curve,* not from counting people one by one, and the
  comparison group took the questionnaire online, so it does not represent any particular
  country.

== About the questionnaire
The statements are the 50 Big-Five Factor Markers of the International Personality Item Pool
(IPIP), a public-domain set developed by Lewis R. Goldberg. The test is adaptive, so you
usually answer fewer than all 50: it stops asking about a trait once its score is precise
enough.
