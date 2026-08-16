import { HerbRuntime } from "/assets/herb-runtime.js"

const { slots } = HerbRuntime.init()

const app = document.querySelector(".todoapp")

// Every interaction is the same request: say what happened, get back what the page renders now.
// Nothing here knows what a todo looks like, which is the point. The template does.
const ask = async (params) => {
  const url = new URL(location.href)

  for (const [key, value] of Object.entries(params)) url.searchParams.set(key, value)

  url.searchParams.set("format", "slots")

  const report = slots.apply(await (await fetch(url)).json())

  // An input the user has typed into keeps showing what they typed, whatever its attribute says.
  for (const input of app.querySelectorAll("input.edit")) input.value = input.getAttribute("value") ?? ""

  // `checked` is presence, not value, so no slot can express it: a value can say "" but not "absent".
  // The server sends the state as an ordinary attribute and the checkbox is set from it.
  for (const box of app.querySelectorAll("input[data-checked]")) box.checked = box.dataset.checked === "true"

  url.searchParams.delete("format")
  for (const key of ["do", "id", "title"]) url.searchParams.delete(key)

  history.replaceState({}, "", url)

  if (report.deferred.length > 0) console.warn("deferred", report.deferred)
}

const id = (target) => target.closest("li[id]")?.id

app.addEventListener("submit", (event) => {
  event.preventDefault()

  const input = event.target.querySelector(".new-todo")
  const title = input.value

  input.value = ""

  ask({ do: "add", title })
})

app.addEventListener("click", (event) => {
  const target = event.target

  if (target.matches('[data-role="toggle"]')) return void ask({ do: "toggle", id: id(target) })
  if (target.matches('[data-role="destroy"]')) return void ask({ do: "destroy", id: id(target) })
  if (target.matches('[data-role="toggle-all"]')) return void ask({ do: "toggle-all" })
  if (target.matches('[data-role="clear"]')) return void ask({ do: "clear" })

  if (target.matches('[data-role="filter"]')) {
    event.preventDefault()

    return void ask({ filter: new URL(target.href).searchParams.get("filter") })
  }
})

// Editing happens on the row's own input, never on the label, because the label is a slot: typing
// into it would leave what was typed beside what the server sends back.
app.addEventListener("dblclick", (event) => {
  const row = event.target.closest("li[id]")

  if (!row || !event.target.matches('[data-role="title"]')) return

  row.classList.add("editing")
  row.querySelector(".edit").focus()
})

const finish = (input, save) => {
  const row = input.closest("li[id]")

  row.classList.remove("editing")

  if (save) ask({ do: "edit", id: row.id, title: input.value })
  else input.value = input.getAttribute("value") ?? ""
}

app.addEventListener("keydown", (event) => {
  if (!event.target.matches(".edit")) return

  if (event.key === "Enter") finish(event.target, true)
  if (event.key === "Escape") finish(event.target, false)
})

app.addEventListener("focusout", (event) => {
  if (event.target.matches(".edit") && event.target.closest(".editing")) finish(event.target, true)
})
