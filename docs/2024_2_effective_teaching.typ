// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let suppl = it.at("supplement", default: none)
  if suppl == none or suppl == auto {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let target = query(it.target, loc).first()
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}



#let article(
  title: none,
  authors: none,
  date: none,
  abstract: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)

  if title != none {
    align(center)[#block(inset: 2em)[
      #text(weight: "bold", size: 1.5em)[#title]
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[Abstract] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
#show: doc => article(
  title: [Preparing Lecture],
  authors: (
    ( name: [CTTI, goAJKMay 07, 2024],
      affiliation: [],
      email: [] ),
    ),
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)


== About Me
<about-me>
#block[
#block[
#box(width: 600, image("images/profile-pic.png"))

]
#block[
#block[
- Ph.D \(Economics) — Pakistan Institute of Development Economics, 2007
- Director, School of Economics \(2019-Jan-22)
- Registrar\(2020-2021), Quaid-i-Azam University, Islamabad
- Specializations:
  - Applied Econometrics
  - Data Analyst
  - Trainer
- Research interests : data for policy, data and analytical skill development ,data for policy

]
]
]
== 
<section>
#block[
#emph["If we want to move from a future we dont want to a future we want, we have to consciously practice bold thinking to achieve the desired future."]

]
== 
<section-1>
#block[
#emph["If we want to move from a future we dont want to a future we want, we have to consciously practice bold thinking to achieve the desired future."]

]
== 
<section-2>
- === Your goal as a teacher
  <your-goal-as-a-teacher>

- === My goal for today \(gup-shup)
  <my-goal-for-today-gup-shup>

- === Your dream, big dream
  <your-dream-big-dream>

- === Excellent teacher \(e.g) goal, what you are doing for it
  <excellent-teacher-e.g-goal-what-you-are-doing-for-it>

- === Are you a joker
  <are-you-a-joker>

- === Books vs Food
  <books-vs-food>

- === Are you waiting for favorable season?
  <are-you-waiting-for-favorable-season>

- === What do you do on weekends
  <what-do-you-do-on-weekends>

- === What you have browsed during last one month
  <what-you-have-browsed-during-last-one-month>

- === What you are discussing with each other
  <what-you-are-discussing-with-each-other>

:::

== #box(width: 1300, image("images/mandela.jpg"))
<section-3>
#block[
Where is this weapon in our society Why dont we have this weapons? Can we have this weapon by degrees? If so then AJK is one of the most literate region than most regions of Pakistan? How many of you want independent Kashmir? How many of you have written blogs on it \(how many sleepless nights you have to achieve this objective)? If none, then we dont want to move to a new future

]
== Why do we teach?
<why-do-we-teach>
#block[
- #strong[What is your mission of teaching?]

- #strong[What is happening when we teach?]

- #strong[What is teaching?]

]
#block[
The opportunity to profoundly impact the lives of children. We think we have an impact to shape better future Mission: My mission is transform students to think deeply, critically and challenge themselves and put them on a learning path

]
== Contents
<contents>
#block[
+ #strong[Requirements of a good teacher]

+ #strong[Types of Teacher]

+ #strong[Lecturing]

+ #strong[Requirements of Successful Lecturing]

+ #strong[Oral presentation Material and Methods]

+ #strong[Requirements of Ideal effective lecturing]

]

#horizontalrule

#block[
#block[
#set enum(numbering: "1.", start: 7)
+ #strong[Characteristics of Good Instructions.]

+ #strong[Structure of the lecture]

+ #strong[Summary of the requirements for an ideal and effective lecture]

+ #strong[Closure]

+ #strong[Summary]

+ #strong[Conclusion]
]

]

#horizontalrule

== How to become a good teacher?
<how-to-become-a-good-teacher>
#align(center)[
#box(width: 676, image("images/good_teacher1.jpg"))
]
== Modes of communication
<modes-of-communication>
#block[
- #strong[Verbal] #strong[– speaking words. Voice tone/pitch/volume.]

- #strong[Intonation] #strong[: sarcastic, sad Word choice : lecture , friends , scientific meeting,]

- #strong[Nonverbal] #strong[: Knowledge ,skill & eye contact ,. body language, facial expression , gestures.]

- #strong[Written Communication ; Explain ?]

]
== Types of Teachers
<types-of-teachers>
#block[
- #strong[A mediocre Teacher : Tells]
- #strong[A good Teacher : explains]
- #strong[A superior Teacher : demonstrates]
- #strong[A great Teacher : inspires]
- #strong[A great Teacher uses : E C M T]
- #strong[\(];#strong[Effective Classroom Management Techniques)]

]
== #link("pollev.com")[polleverywhere]
<polleverywhere>
#block[
#link("https://pollev-embeds.com/free_text_polls/lMfTtIjDiyJAdppRzvQbb")[An ideal teacher]

]
#block[
World is changing rapidly

luck and preparedness

daily microgains

average life

commitment, conviction, consistency, clarity

]
== Lecturing
<lecturing>
=== is a process by which knowledge is transferred from the teacher \(expert) to young learners\(students). Unfortunately, there is no single magical formula for that but still quite possible by following a series of steps and procedures which I hope will be made part of this training.
<is-a-process-by-which-knowledge-is-transferred-from-the-teacher-expert-to-young-learnersstudents.-unfortunately-there-is-no-single-magical-formula-for-that-but-still-quite-possible-by-following-a-series-of-steps-and-procedures-which-i-hope-will-be-made-part-of-this-training.>
== Lecturer Job
<lecturer-job>
#block[
Lessen student fears and encourage students to pursue deeper understanding

- Through several teaching and curriculum approaches

- integration during the class;

- expanded opportunities for two-way communication;

- developing co-ownership of the course along with the students;

- alternating lecture with small-group work to aid in learning difficult topics.

]
== Poor slide
<poor-slide>
- #strong[#emph[Some students seem naturally enthusiastic about learning, but many need-or expect-their instructors to inspire, challenge, and stimulate them:];]

- #strong[#emph[“Effective learning in the classroom depends on the teacher’s ability … ??];]

- a-#strong[Improving teaching provision within the department by identifying models of best practice and promoting new teaching initiatives and curriculum development.]

- b- #strong[Promote links with other departments and/or disciplines where possible.]

== Favorable classroom atmosphere
<favorable-classroom-atmosphere>
#block[
- #strong[Some students seem naturally enthusiastic about learning, but many need-or expect-their instructors to inspire, challenge, and stimulate them:]

- #strong[“Effective learning in the classroom depends on the teacher’s ability … ??]

]
== Teaching Modules
<teaching-modules>
#block[
- a-#strong[Improving teaching provision within the department by identifying models of best practice and promoting new teaching initiatives and curriculum development.]

- b- #strong[Promote links with other departments and/or disciplines where possible.]

- #strong[Trans-disciplinary and multidisciplinary]

]
== #strong[Interactive Learning]
<interactive-learning>
#block[
- #strong[Course assessment]

- #strong[Students assessment]

- #strong[Teaching Methods]

- #strong[A thousand teachers, a thousand methods.];\(Chinese proverb)

]
== Oral Presentation: Methods and Materials
<oral-presentation-methods-and-materials>
#block[
- YOUR VOICE

- BODY LANGUAGE

- APPEARANCE

- Speed

]
#block[
+ Voice: audibility, pitch, pronunciation, pause. tone?.) How do you relieve monotony in your lecture?
+ BODY LANGUAGE\(Gestures ,pacing but no unpleasant movements) 3.APPEARANCE \(posture , .freezing in one corner?)
+ Speed

]
== Closure
<closure>
#block[
+ #strong[No single teaching method covers everything]

+ #strong[Optimal approach features a mixture of instructional methods and learning activities]

+ #strong[Optimal mixture changes over time with change in students?]

+ #strong[Students involvement in the learning process]

+ #strong[Favorable classroom environment]

]
== Summary
<summary>
- #strong[What one thing did you learn today?]

- #strong[How does today’s lesson impact your understanding?]

- #strong[How would you summarize today’s lecture for someone who wasn’t here?]

- #strong[What was the most significant learning from today’s lecture?]

- #strong[What was the most difficult concept in today’s lecture?]

- #strong[What should I review further in our next lecture?]

- #strong[What was one thing you were unsure about in the lecture ?]

- #strong[Clarify areas of confusion]

#block[
So why not have summary notes polleverywhere.com for class activity If you notice I have one light Green color theme for all slides

]
= #link("https://youtu.be/8qIqwqgtz9o")[How to beat death by powerpoint]
<how-to-beat-death-by-powerpoint>
#link("https://prezi.com/p/l_3m9psa1d_j/how-to-avoid-death-by-powerpoint/")[Perezi on death by PPT]

#link("https://www.forbes.com/sites/forbesbusinessdevelopmentcouncil/2020/02/19/how-to-avoid-death-by-powerpoint/?sh=639420f324d2")[Forbes on how to avoid death by PPT]

== #link("https://www.branchtrack.com/projects/bv28y7r3")[Effective Presentation]
<effective-presentation>
#box(width: 438.82105263157894pt, image("images/presentation_sim.png"))

= #link("https://hbr.org/2013/06/how-to-give-a-killer-presentation")[How to Give a Killer Presentation HBR]
<how-to-give-a-killer-presentation-hbr>
= The ability to learn faster than your competitors may be the only sustainable competitive advantage
<the-ability-to-learn-faster-than-your-competitors-may-be-the-only-sustainable-competitive-advantage>
#block[
Peter Senge: The Fifth Discipline

]
== 
<section-4>
#block[
#block[
#image("images/gr8_teacher.webp");#link("https://owlcation.com/academia/Characteristics-Of-A-Good-Teacher")[What makes a great teacher? A brief summary]

]
#block[
#block[
- Expert communication skills
- Superior listening skills
- Deep knowledge and passion for their subject matter
- The ability to build caring relationships with students
- Friendliness and approachability
- Excellent preparation and organization skills
- Strong work ethic
- Community-building skills
- High expectations for all

]
]
]
== Digital era education: challenges and oppotunities
<digital-era-education-challenges-and-oppotunities>
#block[
- #link("khanacademy.com")[Immense learning sources]
- #link("youtube.com")[youtube] and
- much more
- #link("https://galtonboard.com/")[Galton Board]
- #link("https://phet.colorado.edu/sims/html/plinko-probability/latest/plinko-probability_en.html")[Plinko]
- Flip based class room teaching

]
== 
<section-5>
#link("https://www.youtube.com/watch?v=UCFg9bcW7Bk")[Teaching methods for inspiring students of the future]

#block[
- "#strong[The mind is not a vessel that needs filling, but wood that needs igniting.];" Plutarch AD46-AD120

- "#strong[Education is not the learning of facts, but the training of the mind to think.];" Abert Einstein 1879-1955

]
== 
<section-6>
#strong[Allow students to engage in:]

#block[
- #strong[Choice]

- #strong[Collaboration]

- #strong[Communication];#link("https://www.pewresearch.org/fact-tank/2015/02/19/skills-for-success/")[recent survey by the Pew Research Center];,

- #strong[Critical Thinking]

- #strong[Creativity] and #strong[greatest of all these is]

- #strong[LOVE]

]
== 
<section-7>
#block[
- I #emph[am a great] TEACHER

- BECAUSE…

- Celebrate mistakes

- Appreciate differences

- Relay feedback

- Evaluate themselves

]
== 
<section-8>
#block[
#strong[“I have learned that people will forget what you said];, people will forget what you #strong[did];, but people will never forget how you made them #strong[feel];.” -Maya Angelou

]
== 
<section-9>
#block[
#strong[“I have learned that people will forget what you said];, people will forget what you #strong[did];, but people will never forget how you made them #strong[feel];.” -Maya Angelou

]
= #link("https://economistwritingeveryday.com/2024/01/19/teaching-taxes-w-gifs/")[Lets learn little bit about Economics]
<lets-learn-little-bit-about-economics>
== 
<section-10>
#figure([
#box(width: 1200.0pt, image("images/ds1.gif"))
], caption: figure.caption(
position: bottom, 
[
Demand Increase
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


== 
<section-11>
#box(width: 1200.0pt, image("images/ds2.gif")) \#\#

#figure([
#box(width: 1200.0pt, image("images/ds3.gif"))
], caption: figure.caption(
position: bottom, 
[
Demand and Supply increase
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


== 
<section-12>
#figure([
#box(width: 1200.0pt, image("images/ds4.gif"))
], caption: figure.caption(
position: bottom, 
[
Demand and Supply increase
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


= Lets’ learn taxes and welfare
<lets-learn-taxes-and-welfare>
== 
<section-13>
#figure([
#box(width: 1200.0pt, image("images/welfareda.gif"))
], caption: figure.caption(
position: bottom, 
[
CS & PS increase
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#block[
First, see the below gif. It shows us that both consumer surplus \(blue area) and producer surplus \(red area) always rise if there is a demand increase \(assuming the law of supply and law of demand).

]
== 
<section-14>
#figure([
#box(width: 1200.0pt, image("images/2tax.gif"))
], caption: figure.caption(
position: bottom, 
[
Higher the taxes, lower the welfare
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#block[
Now, see the below gif. It shows us that both consumer surplus \(blue area) and producer surplus \(red area) always fall if there is a tax increase \(assuming the law of supply and law of demand).

]
== 
<section-15>
Combine the two ideas of taxes and welfare

#figure([
#box(width: 1200.0pt, image("images/2taxwelfare.gif"))
], caption: figure.caption(
position: bottom, 
[
Laffer curve on RHS
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


== 
<section-16>
#figure([
#box(width: 1200.0pt, image("images/ewelfare-1.gif"))
], caption: figure.caption(
position: bottom, 
[
Welfare loss is not shared equally
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


== 
<section-17>
#box(width: 1200.0pt, image("images/2subsidywelfare.gif"))

== 
<section-18>
#box(width: 1200.0pt, image("images/taxdet.gif"))

= #link("https://chat.openai.com/chat/66cabaf0-a865-4b18-82e6-bee97f6f427c")[ChatGPT]
<chatgpt>
= #link("https://chat.openai.com/chat")[Role of a teacher in ChatGPT Era]
<role-of-a-teacher-in-chatgpt-era>
== 
<section-19>
=== لوئے لوئے پرہ لے کڑ یے پانڈا جے پانڈا تدھ پر ہنا
<لوئے-لوئے-پرہ-لے-کڑ-یے-پانڈا-جے-پانڈا-تدھ-پر-ہنا>
=== شام پئی بن شام محمد تو کرہ جاندی نے ڈرنا
<شام-پئی-بن-شام-محمد-تو-کرہ-جاندی-نے-ڈرنا>
= Stay Hungry, Stay Foolish
<stay-hungry-stay-foolish>



