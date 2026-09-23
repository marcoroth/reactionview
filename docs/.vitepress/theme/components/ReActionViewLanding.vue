<script setup>
const companies = [
  { login: "Light-Labs-Technologies", name: "Light Labs" },
  { login: "renuo", name: "renuo" },
  { login: "honestica", name: "Lifen" },
  { login: "typesense", name: "Typesense" },
  { login: "ventrata", name: "Ventrata" },
  { login: "BaseSecrete", name: "Base Secrète" },
  { login: "beflagrant", name: "Flagrant" },
  { login: "linkanalabs", name: "Linkana" },
  { login: "avo-hq", name: "Avo" },
  { login: "practical-computer", name: "Practical Computer" },
]

const people = [
  "wbotelhos", "jespr", "DRBragg", "peterberkenbosch", "kcdragon", "ChaelCodes",
  "larouxn", "lxxxvi", "williamkennedy", "janko", "irinanazarova", "gurgeous",
  "kdaigle", "rafaelfranca", "cb341", "myabc", "ajaya", "doolin", "sobstel",
  "apiguy", "rosa", "tysongach", "palkan", "itsameandrea", "markokajzer",
  "chris-biagini",
]

const total = companies.length + people.length
</script>

<template>
  <div class="rav-landing">
    <div class="wrap">
      <header class="hero">
        <div class="hero-grid">
          <div class="hero-copy">
        <h1>Reactive views for the <em>HTML+ERB</em> you already have.</h1>

        <p class="hero-sub">You get what a client-side framework gives you, without adopting one.</p>

        <ul class="marks">
          <li>No new syntax</li>
          <li>No client framework</li>
          <li>No API layer</li>
          <li>No build step</li>
        </ul>

        <div class="cta-row">
          <a class="btn btn-primary" href="/overview">Get started</a>
          <a class="btn btn-secondary" href="/quick-start">Quick Start</a>
          <a class="btn btn-secondary" href="https://github.com/marcoroth/reactionview">GitHub</a>
        </div>
          </div>

          <div class="hero-art">
            <img src="/reactionview.png" alt="ReActionView" width="260" height="260" data-no-zoom>
          </div>
        </div>

        <div class="hero-demo">
          <p class="term-label">app/views/messages/index.html.erb</p>
          <pre class="term"><span class="dim">&lt;%#</span> <span class="attr">herb:slots</span> <span class="dim">%&gt;</span>
<span class="dim">&lt;%#</span> <span class="attr">herb:state</span> (composing: <span class="g">false</span>) <span class="dim">%&gt;</span>

<span class="tag">&lt;button</span> <span class="attr">data-herb-toggle</span><span class="eq">=</span><span class="str">"composing"</span><span class="tag">&gt;</span>New message<span class="tag">&lt;/button&gt;</span>

<span class="erb">&lt;% if composing %&gt;</span>
  <span class="tag">&lt;form</span> <span class="attr">action</span><span class="eq">=</span><span class="str">"/messages"</span> <span class="attr">method</span><span class="eq">=</span><span class="str">"post"</span><span class="tag">&gt;</span>
    <span class="tag">&lt;input</span> <span class="attr">name</span><span class="eq">=</span><span class="str">"message[body]"</span><span class="tag">&gt;</span>
  <span class="tag">&lt;/form&gt;</span>
<span class="erb">&lt;% end %&gt;</span></pre>
          <p class="caption">The button flips a state the browser owns, so the form appears without a page load and the list above it stays exactly where it was.</p>
        </div>
      </header>

      <section>
        <div class="sec-head">
          <h2>You write it all in the template.</h2>
          <p>Declare state, change it from an attribute, read it anywhere in the same file. When a change needs the database, the controller you already have handles it, and only the parts that changed get updated.</p>
        </div>

        <div class="caps">
          <div class="cap">
            <div class="cap-text">
              <h3>Fine-grained reactivity</h3>
              <p>Declare a state at the top of the template and read it anywhere below. Change it, and every spot that reads it updates, down to a single value, an attribute or one row of a list. Nothing else on the page is touched, so open menus stay open, inputs keep what you typed, and the scroll position does not jump.</p>
            </div>
            <div>
              <pre class="term"><span class="dim">&lt;%#</span> <span class="attr">herb:state</span> (draft: <span class="str">""</span>) <span class="dim">%&gt;</span>

<span class="tag">&lt;textarea&gt;</span><span class="erb">&lt;%= draft %&gt;</span><span class="tag">&lt;/textarea&gt;</span>
<span class="tag">&lt;p&gt;</span><span class="erb">&lt;%= draft.length %&gt;</span> characters<span class="tag">&lt;/p&gt;</span></pre>
            </div>
          </div>

          <div class="cap">
            <div class="cap-text">
              <h3>When the server has to answer</h3>
              <p>Sorting and filtering need the database, and the browser cannot run Ruby. So the client requests the same URL again, your controller runs like it always does, and <code>herb_state</code> tells you what the browser currently holds. You render the same template, and only the values that changed go back.</p>
            </div>
            <div>
              <pre class="term"><span class="dim">GET</span> /messages?format=slots
<span class="dim">Accept:</span> application/vnd.herb.slots+json
<span class="dim">Herb-State:</span> {<span class="str">"order"</span>: <span class="str">"newest"</span>}

<span class="dim">#</span> app/controllers/messages_controller.rb
direction = <span class="g">herb_state</span>(<span class="str">"order"</span>, <span class="str">"oldest"</span>)
@messages = Message.order(created_at: direction)</pre>
            </div>
          </div>

          <div class="cap">
            <div class="cap-text">
              <h3>Mistakes show up while you work</h3>
              <p>A mismatched tag, or a <code>&lt;div&gt;</code> inside a <code>&lt;p&gt;</code>, shows up in the browser with the file and the line. In tests it fails instead of shipping. The panel in the corner tells you which template rendered an element, how long it took, and what it queried.</p>
            </div>
            <div>
              <pre class="term"><span class="r">✘</span> <span class="bold">InvalidNestingError</span>
  Block element <span class="attr">&lt;div&gt;</span> cannot be nested
  inside <span class="attr">&lt;p&gt;</span> at line 4

  <span class="dim">app/views/pages/nesting.html.erb:4:3</span>

<span class="dim">Render stack</span>
  pages/nesting.html.erb:4:3
  layouts/application.html.erb</pre>
            </div>
          </div>
        </div>
      </section>

      <section>
        <div class="split">
          <div class="pointer">
            <h3>Works with Hotwire</h3>
            <p>Turbo still drives navigation, and Stimulus is still the place for behavior that is more than writing a value. Markup arriving from a Turbo visit, frame or stream is picked up on its own, and a Stimulus controller can read and write the same states your template declares.</p>
            <p><a href="/guides/stimulus-and-turbo">Stimulus and Turbo →</a></p>
          </div>
          <div class="pointer">
            <h3>Built on Herb</h3>
            <p>ReActionView renders with <code>Herb::Engine</code>, which reads the HTML and the Ruby in a template as one language. Every bit of syntax on this page is documented over in the Herb language reference.</p>
            <p><a href="https://herb-tools.dev/language/">Herb Language reference →</a></p>
          </div>
        </div>
      </section>

      <section>
        <div class="sec-head">
          <h2>Supported by {{ total }} people and companies.</h2>
          <p>ReActionView is part of the <a href="https://herb-tools.dev">Herb</a> project, which is funded by the people and companies sponsoring it on GitHub.</p>
        </div>

        <p class="sponsor-label">Companies</p>
        <ul class="orgs">
          <li v-for="company in companies" :key="company.login">
            <a :href="`https://github.com/${company.login}`">
              <img :src="`https://github.com/${company.login}.png?size=80`" :alt="company.name" width="28" height="28" loading="lazy" data-no-zoom>
              <span>{{ company.name }}</span>
            </a>
          </li>
        </ul>

        <p class="sponsor-label">People</p>
        <ul class="people">
          <li v-for="login in people" :key="login">
            <a :href="`https://github.com/${login}`" :title="login">
              <img :src="`https://github.com/${login}.png?size=80`" :alt="login" width="40" height="40" loading="lazy" data-no-zoom>
            </a>
          </li>
        </ul>

        <p class="sponsor-note">
          <a class="btn btn-secondary" href="https://github.com/sponsors/marcoroth">Sponsor ReActionView on GitHub</a>
        </p>
        <p class="sponsor-why">ReActionView is created and led by <a href="https://github.com/marcoroth">Marco Roth</a>, with help from its contributors.</p>
      </section>

      <section class="closing">
        <div class="sec-head">
          <h2>Install it in your Rails app.</h2>
          <p>Two commands, and you are running it. Ruby 3.2 or newer, Rails 7.0 or newer.</p>
        </div>

        <pre class="term"><span class="dim">$</span> bundle add reactionview
<span class="dim">$</span> bin/rails generate reactionview:install</pre>

        <div class="cta-row" style="margin-top: 2rem;">
          <a class="btn btn-primary" href="/installation">Setup</a>
          <a class="btn btn-secondary" href="/quick-start">Quick Start</a>
        </div>

        <p class="note">Reactive templates are experimental. They need ReActionView <code>^0.6.0</code> and Herb <code>^0.11.0</code>, and their markup, payload and JavaScript API may change between releases.</p>
      </section>
    </div>
  </div>
</template>

<style>
.rav-landing {
  --ground: var(--vp-c-bg);
  --surface: var(--vp-c-bg-soft);
  --ink: var(--vp-c-text-1);
  --ink-soft: var(--vp-c-text-2);
  --ink-faint: var(--vp-c-text-3);
  --rule: var(--vp-c-divider);
  --accent: var(--vp-c-brand-1);
  --accent-soft: var(--vp-c-brand-soft);
  --accent-line: var(--vp-c-brand-2);
  --term-bg: #0f1815;
  --term-fg: #dfe8e1;
  --term-dim: #6e837a;
  --term-green: #7fcfa0;
  --term-red: #e08878;
  --mono: var(--vp-font-family-mono);
  --measure: 64ch;
  --pad: clamp(1.25rem, 5vw, 3.5rem);

  color: var(--ink);
  font-size: 1.0625rem;
  line-height: 1.65;
}

.rav-landing { padding: 0 1.5rem; }
@media (min-width: 48rem) { .rav-landing { padding: 0 2rem; } }
.rav-landing .wrap { max-width: calc(var(--vp-layout-max-width) - 4rem); margin: 0 auto; padding: 0; }
.rav-landing h1, .rav-landing h2, .rav-landing h3 { margin: 0; line-height: 1.1; text-wrap: balance; }
.rav-landing p { margin: 0 0 1.1rem; }
.rav-landing p:last-child { margin-bottom: 0; }
.rav-landing code { font-family: var(--mono); font-size: 0.9em; }
.rav-landing a { color: inherit; }


.rav-landing .hero { padding: clamp(3rem, 7vw, 5.5rem) 0 clamp(2.5rem, 5vw, 4rem); }
.rav-landing .hero-grid { display: grid; gap: 2rem; grid-template-columns: 1fr; align-items: center; }
@media (min-width: 58rem) {
  .rav-landing .hero-grid { grid-template-columns: minmax(0, 46rem) 17rem; gap: 3rem; justify-content: space-between; }
}
.rav-landing .hero-art { display: flex; justify-content: flex-start; order: -1; }
.rav-landing .hero-art img { width: clamp(7.5rem, 26vw, 15rem); height: auto; }
@media (min-width: 58rem) {
  .rav-landing .hero-art { justify-content: center; order: 0; }
}
.rav-landing .hero h1 {
  font-size: clamp(2.3rem, 5.6vw, 3.9rem); font-weight: 700;
  letter-spacing: -0.035em; max-width: 19ch; margin-bottom: 1.4rem;
}
.rav-landing .hero h1 em { font-style: normal; color: var(--accent); }
.rav-landing .hero-sub {
  font-size: clamp(1.05rem, 1.9vw, 1.25rem); color: var(--ink-soft);
  max-width: 54ch; margin: 0 0 1.75rem; line-height: 1.55;
}


.rav-landing .cta-row { display: flex; flex-wrap: wrap; gap: 0.7rem; }
.rav-landing .btn {
  display: inline-block; font-weight: 600; font-size: 0.9375rem;
  padding: 0.68rem 1.25rem; border-radius: 3px; text-decoration: none;
  border: 1px solid transparent; transition: opacity 0.15s;
}
.rav-landing .btn-primary { background: var(--accent); color: var(--vp-c-white); }
.rav-landing .btn-secondary { border-color: var(--rule); color: var(--ink); }
.rav-landing .btn:hover { opacity: 0.85; }

.rav-landing .term {
  background: var(--term-bg); color: var(--term-fg);
  font-family: var(--mono); font-size: 0.8125rem; line-height: 1.75;
  border-radius: 5px; padding: 1.15rem 1.35rem; overflow-x: auto;
  margin: 0; white-space: pre;
}
.rav-landing .dim { color: var(--term-dim); }
.rav-landing .g { color: var(--term-green); }
.rav-landing .r { color: var(--term-red); }
.rav-landing .bold { font-weight: 600; }
.rav-landing .tag { color: #e06c75; }
.rav-landing .attr { color: #d19a66; }
.rav-landing .eq { color: #56b6c2; }
.rav-landing .str { color: #98c379; }
.rav-landing .erb { color: #be5046; }

.rav-landing .term-label {
  font-family: var(--mono); font-size: 0.75rem; letter-spacing: 0.01em;
  color: var(--ink-faint); margin: 0 0 0.55rem;
}
.rav-landing .hero-demo { margin-top: 3rem; max-width: 72rem; }
.rav-landing .caption { font-size: 0.9375rem; color: var(--ink-soft); margin: 0.9rem 0 0; max-width: var(--measure); }

.rav-landing section { padding: clamp(3rem, 6.5vw, 5rem) 0; border-top: 1px solid var(--rule); }
.rav-landing .sec-head { margin-bottom: 2.5rem; }
.rav-landing .sec-head h2 { font-size: clamp(1.65rem, 3.4vw, 2.4rem); font-weight: 500; letter-spacing: -0.028em; max-width: 24ch; }
.rav-landing .sec-head p { color: var(--ink-soft); max-width: var(--measure); margin: 1rem 0 0; }

.rav-landing .split { display: grid; gap: 1.5rem; grid-template-columns: 1fr; align-items: start; }
@media (min-width: 58rem) { .rav-landing .split { grid-template-columns: 1fr 1fr; gap: 2rem; } }

.rav-landing .caps { display: grid; gap: 2.5rem; }
.rav-landing .cap { display: grid; gap: 1.25rem; grid-template-columns: 1fr; align-items: center; }
@media (min-width: 58rem) {
  .rav-landing .cap { grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 2.75rem; }
  .rav-landing .cap:nth-child(even) > .cap-text { order: 2; }
}
.rav-landing .cap h3 { font-size: 1.1875rem; font-weight: 600; margin-bottom: 0.45rem; letter-spacing: -0.015em; }
.rav-landing .cap p { color: var(--ink-soft); font-size: 0.9688rem; margin: 0; }


.rav-landing .pointer {
  background: var(--surface); border: 1px solid var(--rule);
  border-left: 3px solid var(--accent); border-radius: 4px; padding: 1.6rem 1.75rem;
}
.rav-landing .pointer h3 { font-size: 1.25rem; font-weight: 600; margin-bottom: 0.6rem; letter-spacing: -0.018em; }
.rav-landing .pointer p { color: var(--ink-soft); font-size: 0.9688rem; }
.rav-landing .pointer a { color: var(--accent); font-weight: 600; text-decoration: none; }
.rav-landing .pointer a:hover { text-decoration: underline; }

.rav-landing .marks {
  display: flex; flex-wrap: wrap; gap: 0.5rem 0.6rem; margin: 0 0 2.25rem;
  list-style: none; padding: 0;
}
.rav-landing .marks li {
  font-weight: 500; font-size: 0.9375rem; letter-spacing: -0.01em;
  padding: 0.4rem 0.85rem; border: 1px solid var(--accent-line);
  border-radius: 999px; color: var(--accent); background: var(--accent-soft);
}

.rav-landing .sec-head a { color: var(--accent); font-weight: 500; text-decoration: none; }
.rav-landing .sec-head a:hover { text-decoration: underline; }
.rav-landing .sponsor-label { font-family: var(--mono); font-size: 0.8125rem; color: var(--ink-faint); margin: 2.25rem 0 1rem; }
.rav-landing .orgs {
  display: grid; gap: 0.6rem; grid-template-columns: repeat(auto-fill, minmax(12.5rem, 1fr));
  list-style: none; padding: 0; margin: 0;
}
.rav-landing .orgs li { display: flex; }
.rav-landing .orgs a {
  display: flex; flex: 1; align-items: center; gap: 0.7rem; text-decoration: none;
  padding: 0.6rem 0.85rem; border: 1px solid var(--rule); border-radius: 6px;
  background: var(--surface); transition: border-color 0.15s;
}
.rav-landing .orgs a:hover { border-color: var(--accent-line); }
.rav-landing .orgs img { width: 28px; height: 28px; border-radius: 5px; flex: none; background: var(--surface); }
.rav-landing .orgs span { font-size: 0.875rem; font-weight: 500; color: var(--ink); line-height: 1.25; }
.rav-landing .people { display: flex; flex-wrap: wrap; gap: 0.5rem; list-style: none; padding: 0; margin: 0; }
.rav-landing .people a { display: block; border-radius: 50%; transition: transform 0.15s; }
.rav-landing .people a:hover { transform: translateY(-2px); }
.rav-landing .people img { width: 40px; height: 40px; border-radius: 50%; display: block; background: var(--surface); border: 1px solid var(--rule); }
.rav-landing .sponsor-why {
  margin-top: 0.9rem; color: var(--ink-soft); font-size: 0.9375rem; max-width: var(--measure);
}
.rav-landing .sponsor-why a { color: var(--accent); font-weight: 500; text-decoration: none; }
.rav-landing .sponsor-why a:hover { text-decoration: underline; }
.rav-landing .sponsor-note { margin-top: 2rem; color: var(--ink-soft); font-size: 0.9375rem; max-width: var(--measure); }
.rav-landing .sponsor-note a { color: var(--accent); font-weight: 600; text-decoration: none; }
.rav-landing .sponsor-note a:hover { text-decoration: underline; }

.rav-landing .closing { padding-bottom: 5rem; }
.rav-landing .note { font-size: 0.875rem; color: var(--ink-faint); margin-top: 2rem; max-width: var(--measure); }
</style>
