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
  authors: (
    ( name: [Zahid Asghar],
      affiliation: [],
      email: [] ),
    ),
  date: [2024-09-24],
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)


= AI in Economics
<ai-in-economics>
#strong[Zahid Asghar]

= AI Won’t Replace Humans — But Humans With AI Will Replace Humans Without AI
<ai-wont-replace-humans-but-humans-with-ai-will-replace-humans-without-ai>
== #link("https://hbr.org/2023/08/ai-wont-replace-humans-but-humans-with-ai-will-replace-humans-without-ai")[HBR]
<hbr>

#horizontalrule

= What is AI?
<what-is-ai>
#strong[Artificial Intelligence \(AI):]

- The broad concept where machines simulate human intelligence.

- AI allows machines to perform tasks like decision-making, speech recognition, and problem-solving.

#strong[Examples:]

- Self-driving cars
- Virtual assistants like Siri or Alexa

= What is Machine Learning \(ML)?
<what-is-machine-learning-ml>
#strong[Machine Learning \(ML):]

- A subset of AI that enables machines to learn from data and improve performance over time.

- ML doesn’t require explicit programming for each task.

#strong[Types of ML:]

- Supervised Learning: Uses labeled data.
- Unsupervised Learning: Finds hidden patterns in unlabeled data.
- Reinforcement Learning: Learns through rewards and penalties.

#strong[Examples:] - Netflix recommendation system - Spam filters in email

= What is Natural Language Processing \(NLP)?
<what-is-natural-language-processing-nlp>
#strong[Natural Language Processing \(NLP):]

- A branch of AI focused on the interaction between computers and human \(natural) languages.

- Helps machines understand, interpret, and respond to human language.

#strong[Applications:] - Sentiment analysis \(understanding opinions) - Chatbots and language translation tools

#strong[Examples:] - Google Translate - Virtual Assistants

= Generative AI
<generative-ai>
#strong[Generative AI:]

- A form of AI that creates new content—whether it’s text, images, music, or other media—by learning from patterns in existing data.

- Uses deep learning models such as transformers \(like GPT) and GANs \(Generative Adversarial Networks).

#strong[Examples:] - GPT-4o for text generation - DALL-E for creating images from text descriptions - AI-generated music or art

= Traditional AI vs.~Generative AI
<traditional-ai-vs.-generative-ai>
== Traditional AI
<traditional-ai>
#strong[Definition:]

- Analyzes existing data to uncover patterns, trends, or insights.

#strong[Purpose:] \
- Understand and summarize what’s already there.

#strong[Techniques:] - Statistical analysis, clustering, classification.

#strong[Examples:] - Business reports summarizing sales performance. - Tools like Google Analytics offering insights based on historical data.

= Generative AI
<generative-ai-1>
#strong[Definition:] \
- Focuses on creating new content by learning from existing patterns.

#strong[Purpose:] \
- To generate something new—whether it’s text, art, or even videos.

#strong[Techniques:] - Deep learning models, transformers.

#strong[Examples:] - GPT generating essays, DALL-E creating new images, AI composing music.

#horizontalrule

== Generative AI in a Nutshell
<generative-ai-in-a-nutshell>
#box(width: 1148.9747899159663pt, image("images/AI/genAI1.png"))

#horizontalrule

= 
<section>
#box(width: 1025.546218487395pt, image("images/AI/genAI2.png"))

#horizontalrule

= 
<section-1>
#box(width: 427.15966386554624pt, image("images/AI/genAI3.png"))

#horizontalrule

= 
<section-2>
#box(width: 756.90756302521pt, image("images/AI/genAI4.png"))

#horizontalrule

== LLMs
<llms>
#image("images/AI/LLM.webp")

#horizontalrule

#box(width: 640.0pt, image("images/AI/LLM2.jpg"))

#horizontalrule

#box(width: 1148.9747899159663pt, image("images/AI/genAI6.png"))

#horizontalrule

#box(width: 1148.9747899159663pt, image("images/AI/genAI7.png"))

= Generative AI in a Nutshell
<generative-ai-in-a-nutshell-1>
#box(width: 1273, image("https://blog.crisp.se/wp-content/uploads/2024/01/generative-AI-in-a-nutshell.png"))

#figure(
align(center)[#table(
  columns: 1,
  align: (col, row) => (left,).at(col),
  inset: 6pt,
  [\#\# Traditional AI vs.~Generative AI \(Comparison){.scrollable}],
  [| Feature | #strong[Traditional AI] | #strong[Generative AI] | |———————–|——————————————————–|—————————————————-| | #strong[Function] | Summarizes and analyzes existing data | Creates new content based on learned patterns | | #strong[Output] | Insights, summaries, analysis of existing data | New text, images, music, etc. | | #strong[Examples] | Business reports, trend analysis, sentiment analysis | AI-generated images, articles, music | | #strong[Technologies Used] | Statistical models, clustering, classification | Neural networks \(GANs, transformers) |],
  [\#\# Key Takeaway],
  [- #strong[Artificial Intelligence \(AI)] is the broad field enabling machines to mimic human intelligence.],
  [- #strong[Machine Learning \(ML)] is a technique within AI, focused on learning from data.],
  [- #strong[NLP] allows AI to understand and interact with human language.],
  [- #strong[Generative AI] creates new, original content based on learned patterns.],
  [- #strong[Traditional AI] analyzes existing data to provide insights, while #strong[Generative AI] creates something entirely new.],
  [\#\#\# New Wave of Technology],
  [- What does the wave of technology mean for humanity?],
  [- Historical discoveries: Fire, the wheel, printing press, steel, harnessing electricity],
  [- Transformation of human civilization through technological advancements],
  [\#\#\# Advanced AI and biotechnology],
  [- Benefits: Unlock secrets of the universe , Cure diseases, Create a healthier, sustainable world],
)]
)

== The Dangers
<the-dangers>
- Manipulating DNA: implications for individuals and ecosystems
- Choice: Unparalleled possibilities vs.~unimaginable perils
- Exponential speed of change in technology \(e.g., LLMs)

== The Rise of AI
<the-rise-of-ai>
- Four years ago, no one believed in LLMs, now everyone talks about them

- Future: Superintelligence in the next decade?

- Question: How do we respond?

#horizontalrule

== The Dilemma
<the-dilemma>
- Replicating our unique intelligence

- The Luddite reaction: fears, bans, moratoriums

- Challenge: balancing immense benefits and potential perils

=== The Containment Problem
<the-containment-problem>
- Technology spreads exponentially, nearly impossible to stop

- Examples: Industrial Revolution, AI, Synthetic biology

- Inventions cannot be uninvented; knowledge proliferates

#horizontalrule

== What are you?
<what-are-you>
#block[
- === What are you? Explain in one sentence to a 10 year old.
  <what-are-you-explain-in-one-sentence-to-a-10-year-old.>

- === What are you? Explain in two sentences to a university student.
  <what-are-you-explain-in-two-sentences-to-a-university-student.>

- === What are you? Explain to a university teacher.
  <what-are-you-explain-to-a-university-teacher.>

- === What are you? Explain to an economics research scholar.
  <what-are-you-explain-to-an-economics-research-scholar.>

]

#horizontalrule

== Some more prompting
<some-more-prompting>
=== What role could and should generative AI play for supporting effective and engaging evidence-based learning for economists?
<what-role-could-and-should-generative-ai-play-for-supporting-effective-and-engaging-evidence-based-learning-for-economists>
=== What challenges AI poses to the traditional role of the teacher in the classroom?
<what-challenges-ai-poses-to-the-traditional-role-of-the-teacher-in-the-classroom>
=== What challenges AI poses to policy integrity and evaluation of policies?
<what-challenges-ai-poses-to-policy-integrity-and-evaluation-of-policies>
== Fiscal Policy Advisor
<fiscal-policy-advisor>
=== How do 1% increase in GST affects inflation and its consequences on poor segments of the society?
<how-do-1-increase-in-gst-affects-inflation-and-its-consequences-on-poor-segments-of-the-society>
= What will Iqbal say to youth about use of Social Media
<what-will-iqbal-say-to-youth-about-use-of-social-media>
#block[
Allama Iqbal, known for his deep reflections on spirituality, selfhood \(#emph[Khudi];), and societal progress, would likely have a nuanced view of social media’s impact on youth. Here’s what he might say:

#strong[1. Distraction from Purpose:] \
Iqbal would likely be concerned about social media’s ability to distract youth from their true purpose. He often emphasized the need for deep self-reflection and personal growth, and he might view the constant scrolling and superficial interactions on social media as hindrances to achieving #emph[Khudi];. He might say, #strong[#emph["The pursuit of likes and followers should not replace the pursuit of self-realization and greater goals."];]

#strong[2. Lost Sense of Identity:] \
Iqbal believed in the importance of individual and cultural identity. He might see social media as contributing to a loss of self, where youth are too often influenced by external validation and trends rather than their inner values and cultural heritage. He could warn that #strong[#emph["In a world of filters and illusions, do not lose your true self. Your identity is not what others see online, but what you discover within."];]

#strong[3. Potential for Positive Change:] \
Despite his concerns, Iqbal would recognize the potential of social media as a powerful tool for positive change. He might encourage the youth to use these platforms to raise awareness about important issues, foster meaningful connections, and promote justice and knowledge. He could say, #strong[#emph["Use your voice on these platforms as a means to awaken and uplift, not just to entertain."];]

#strong[4. Spiritual and Intellectual Balance:] \
Iqbal would likely urge the youth to balance their time on social media with activities that promote intellectual growth and spiritual reflection. He might remind them that while social media can be a tool for learning and connection, it should not replace the deeper, more personal journey of seeking knowledge and spiritual fulfillment. He might caution, #strong[#emph["Do not let fleeting moments of entertainment steal the time meant for the pursuit of wisdom and self-enlightenment."];]

#strong[5. The Power of Influence:] \
Iqbal would be keenly aware of social media’s power to influence minds. He would advise youth to be discerning in their consumption of content, warning them not to fall prey to misinformation or hollow trends. He might say, #strong[#emph["Just as a gardener tends to what he plants, so too must you guard your mind from the weeds of falsehood and idle talk."];]

In summary, Iqbal would likely see both the dangers and the opportunities in social media. He would call on the youth to use these platforms wisely, ensuring they foster self-growth, preserve cultural identity, and contribute meaningfully to society, rather than getting lost in the distractions of the digital world.

]

#horizontalrule

== Race between Education and Technology
<race-between-education-and-technology>
#box(width: 496.73949579831935pt, image("images/AI/race_tech_edu.png"))

#block[
Many a times technology races ahead of education. This leads to social pain and inequality. The whole educational system has to revolutionize to keep up. Well, our world has always been in a race between technology and education. Usually, these two go hand in hand, but there are some points in history where technology races so far ahead that education can barely keep pace.

]
== The Role of AI in Idea Generation
<the-role-of-ai-in-idea-generation>
- AI can assist in generating ideas, refining questions, and clarifying thought processes.

- Humans still need to iterate and prototype, but AI can generate a high volume of ideas, which humans often struggle with.

#quote(block: true)[
=== The best way to have a good idea is to have lots of ideas. Humans will need to continue the process of prototyping, testing, and iterating, but humans consistently struggle to produce large quantities of different and new ideas.’
<the-best-way-to-have-a-good-idea-is-to-have-lots-of-ideas.-humans-will-need-to-continue-the-process-of-prototyping-testing-and-iterating-but-humans-consistently-struggle-to-produce-large-quantities-of-different-and-new-ideas.>
]

#horizontalrule

== Comming Wave & Jobs
<comming-wave-jobs>
#block[
- === "AI offers vast tools for augmenting workers and enhancing work. We must master these tools and make them work for us." David Autor
  <ai-offers-vast-tools-for-augmenting-workers-and-enhancing-work.-we-must-master-these-tools-and-make-them-work-for-us.-david-autor>

- ==== As per David Autor, the problem is that older models assumed technology ” might raise some boats more than others, but would’nt lower any boats. However, as digital technology transformed the globaly economy there was "lots of evidence people were made worse off."
  <as-per-david-autor-the-problem-is-that-older-models-assumed-technology-might-raise-some-boats-more-than-others-but-wouldnt-lower-any-boats.-however-as-digital-technology-transformed-the-globaly-economy-there-was-lots-of-evidence-people-were-made-worse-off.>

]
#block[
Let me give you a quick historical example. In the 15th century, technology raced ahead as a great piece of technology was invented: the printing press, which allowed books to be printed much cheaper than ever before. Unfortunately, only a small fraction of the population knew how to read, leading to massive social conflicts and inequality. Ultimately, the whole educational system had to revolutionize to keep up. This led to the birth of the first universities and schools.

]

#horizontalrule

== AI Tutoring : Khanmigo , Conmigo
<ai-tutoring-khanmigo-conmigo>
- "Benjamin Bloom’s 2 Sigma Study"

  - "1-to-1 Tutoring: Two Standard Deviation Improvement"
  - "Unlocking Potential: From Average to Exceptional Students"
  - "AI Tutoring: A Scalable Solution to the 2 Sigma Problem"

- "Introducing Khanmigo: Your Personal AI Tutor"

- "Enhanced Learning Experience: Socratic Conversations"

- "AI Assistance in Math, Programming, and Literature"

- "Empowering Students with Personal Coaching"

- "Guidance, Academic Support, and Career Counseling"

- "AI-Powered Coaching for Every Student"

= Two Sigma Problem
<two-sigma-problem>
#box(width: 1200.0pt, image("images/AI/2_sigma.png"))

#horizontalrule

=== AI Writing Coach
<ai-writing-coach>
- "Collaborative Writing with AI Assistance"
- "Enhancing Writing Skills: AI-Student Collaboration"
- "Feedback, Guidance, and Improvement in Writing"

=== Reading Comprehension
<reading-comprehension>
- "Interactive Reading Comprehension with AI"
- "Analyzing Texts, Answering Questions, and Providing Insights"
- "Enhancing Critical Thinking and Analysis Skills"

#horizontalrule

- "AI in the Classroom: Indo-Pak History Lesson"

- "AI-Powered Teaching Assistant for Teachers"

- "Lesson Planning, Explanation, and Progress Monitoring"

- "Transformative Potential of AI in Education"

- "Enhancing AI Capabilities for a Magical Learning Experience"

- "Combining Human Intelligence with AI for Educational Advancement"

= Paul Samuelson as your Assistant
<paul-samuelson-as-your-assistant>
#block[
=== Give a learning outcomes on consumer theory lecture in 3 points with 15 words for each point
<give-a-learning-outcomes-on-consumer-theory-lecture-in-3-points-with-15-words-for-each-point>
=== Differentiate between Marshalian and Hicksian demand function, restrict response to 50 words
<differentiate-between-marshalian-and-hicksian-demand-function-restrict-response-to-50-words>
=== Explain it in little detail, restrict response to 100 words
<explain-it-in-little-detail-restrict-response-to-100-words>
=== Give some mathematics
<give-some-mathematics>
=== Provide a real life example
<provide-a-real-life-example>
=== Give slides on Marshallian and Hicksian demand function with learning outcomes
<give-slides-on-marshallian-and-hicksian-demand-function-with-learning-outcomes>
=== Provide a quiz on Marshallian and Hicksian demand function
<provide-a-quiz-on-marshallian-and-hicksian-demand-function>
]

#horizontalrule

== The 3 Principles of a Learning Accelerator
<the-3-principles-of-a-learning-accelerator>
#block[
#block[
=== #box(width: 50px, image("https://cdn.jsdelivr.net/gh/twbs/icons@1.9.1/icons/display.svg")) Blended Learning
<blended-learning>
A mix of digital and face-to-face teaching methods to create a flexible learning experience.

#horizontalrule

=== #box(width: 50px, image("https://cdn.jsdelivr.net/gh/twbs/icons@1.9.1/icons/people-fill.svg")) Personalization
<personalization>
Personalization focuses on customizing the learning experience to the unique needs and goals of individual learners.

#horizontalrule

=== #box(width: 50px, image("https://cdn.jsdelivr.net/gh/twbs/icons@1.9.1/icons/share-fill.svg")) Community
<community>
Community builds a network of support and collaboration among learners to enhance the overall learning experience.

]
]

#horizontalrule

== Text to image
<text-to-image>
=== Prompt : Create an image for QAU students sitting as a community learners in a classroom.
<prompt-create-an-image-for-qau-students-sitting-as-a-community-learners-in-a-classroom.>
#block[
#block[
#image("images/AI/interactive_learning.webp")

]
#block[
#image("images/AI/interactive_learning1.webp")

]
]

#horizontalrule

== Old vs New Model
<old-vs-new-model>
#image("images/AI/hall.webp")

Yet, our educational institutions have not evolved much. We still put people in lecture halls for one-size-fits-all teaching, and many companies only offer a couple of days of training per year. This model is outdated.

= Things to be discussed discussed
<things-to-be-discussed-discussed>
- Customised advanced tools: Policy Advisor, Fiscal Policy Advisor, Economics Expert,…

- Coding, Mathematics, Data Analysis …

- Technology’s Impact on Humanity

== Containment: Can We Do It?
<containment-can-we-do-it>
- Navigating the Coming Wave

- AI and Wars

- How Ukraine countered largest every military deployment of Russia

- AI and the Future of Work

#horizontalrule

== Prompt
<prompt>
=== You are hiring a "waiter" The typical daily wage rate is PKR 800. You have 2 candidates. Person 1: Has 1 year\(s) of experience in this role. Requests PKR 1100. Person 2: Has 0 year\(s) of experience in this role. Requests PKR 900. Who would you hire? You have to pick one.
<you-are-hiring-a-waiter-the-typical-daily-wage-rate-is-pkr-800.-you-have-2-candidates.-person-1-has-1-years-of-experience-in-this-role.-requests-pkr-1100.-person-2-has-0-years-of-experience-in-this-role.-requests-pkr-900.-who-would-you-hire-you-have-to-pick-one.>
=== Explain Solow Growth model to an undergraduate studet in 70 words.
<explain-solow-growth-model-to-an-undergraduate-studet-in-70-words.>
=== Simulate the Solow growth model and plot the results in a four chart.
<simulate-the-solow-growth-model-and-plot-the-results-in-a-four-chart.>
= Resources
<resources>
- #link("https://www.youtube.com/watch?v=ArI6albrkuY")[Re-inventing Education for the Digital Age | David Middelbeck | TEDxMünster]

- #link("https://sites.google.com/view/lastunen/ai-for-economists")[AI for Economists: Prompt & Resources]

- #link("https://teachingnaked.com/prompts/")[Teaching Naked Teaching with AI]

- #link("https://www.economist.com/the-economist-explains/2024/01/25/what-is-prompt-engineering-for-artificial-intelligence")[What is Prompt Enginering]

- Policy Advisor

- Fiscal policy advisor

- Economics expert

- Tutor me

- Duolingo

- R for economics and Econometrics

- Stata ai

- curipid.com Lessons in seconds

- murf.ai Text to speech

- Myheritage

- Snythesia video maker

= Books I found useful in 2024
<books-i-found-useful-in-2024>
#block[
#block[
#box(width: 181.0pt, image("images/AI/book1.jpeg"))

]
#block[
#box(width: 183.0pt, image("images/AI/book2.jpeg"))

]
#block[
#box(width: 225.0pt, image("images/AI/book3.jpeg"))

]
#block[
#box(width: 180.0pt, image("images/AI/book4.jpeg"))

]
#block[
#box(width: 183.0pt, image("images/AI/book5.jpeg"))

]
]



