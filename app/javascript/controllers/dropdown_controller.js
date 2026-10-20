import { Controller } from "@hotwired/stimulus"

// Click-to-open menus built on <details>: also close when clicking outside or pressing Escape
export default class extends Controller {
  connect() {
    this.close = this.close.bind(this)
    document.addEventListener("click", this.close)
    document.addEventListener("keydown", this.close)
  }

  disconnect() {
    document.removeEventListener("click", this.close)
    document.removeEventListener("keydown", this.close)
  }

  close(event) {
    if (!this.element.open) return

    const outside = event.type === "click" && !this.element.contains(event.target)
    const escape = event.type === "keydown" && event.key === "Escape"
    if (outside || escape) this.element.open = false
  }
}
