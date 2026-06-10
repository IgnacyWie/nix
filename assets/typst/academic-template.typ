// Shared academic document template for local Typst notes.

#let course-titles = (
  "dam": "Data Acquisition Methods (JBM230)",
  "ds": "Data Statistics (JBM015)",
  "fda": "Foundations of Data Analytics (2IAB1)",
  "discrete": "Discrete Structures (2IT80)",
  "automata": "Automata and Formal Languages (2IRR90)",
  "gpss": "Global Polish Society (GPSS)",
  "ethics": "Data Science Ethics (JBG000)"
)

#let project(
  title: "",
  subject: "",
  author: "Ignacy Kacper Wielogorski",
  student-number: "2297639",
  date: datetime.today().display("[day] [month repr:long] [year]"),
  body
) = {
  let display-subject = course-titles.at(lower(subject), default: subject)

  set text(font: "New Computer Modern", size: 11pt)
  set par(justify: true)

  align(center)[
    #text(size: 17pt, weight: "bold")[#title]
    #v(0.1em)
    #v(0.5em)
    #text(size: 12pt, style: "italic")[#display-subject]

    #v(1em)
    #author -- #student-number

    #v(0.5em)
    #date
  ]

  line(length: 100%, stroke: 0.5pt + gray)
  v(1em)

  body
}
