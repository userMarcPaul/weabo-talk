import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Confirmation card (shared/_confirm_dialog) used by Turbo for every data-turbo-confirm,
// instead of the browser's own confirm(). Optional, on the button or its form:
//   data-confirm-details  text under the question (e.g. "This can't be undone.")
//   data-confirm-button   label of the confirm button (default "Confirm")
export default class extends Controller {
  static targets = ["message", "details", "confirmButton"]

  connect() {
    this.confirm = this.confirm.bind(this)
    Turbo.config.forms.confirm = this.confirm
  }

  disconnect() {
    if (Turbo.config.forms.confirm === this.confirm) Turbo.config.forms.confirm = undefined
  }

  // Resolves to true for the confirm button; false for Cancel, Escape or a click outside the card
  confirm(message, form, submitter) {
    const option = (name) => submitter?.getAttribute(`data-confirm-${name}`) || form.getAttribute(`data-confirm-${name}`)

    this.messageTarget.textContent = message
    this.detailsTarget.textContent = option("details") || ""
    this.detailsTarget.hidden = !option("details")
    this.confirmButtonTarget.textContent = option("button") || "Confirm"

    this.element.returnValue = ""
    this.element.showModal()

    return new Promise((resolve) => {
      this.element.addEventListener("close", () => resolve(this.element.returnValue === "confirm"), { once: true })
    })
  }

  // The dialog element itself is the backdrop: the card fills the rest
  closeOnBackdrop(event) {
    if (event.target === this.element) this.element.close("cancel")
  }
}
