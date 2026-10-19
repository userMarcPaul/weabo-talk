import { Controller } from "@hotwired/stimulus"

/**
 * Post Form Image Management Controller
 * 
 * Handles image-specific functionality:
 * - Adding new image fields dynamically
 * - Removing image fields
 * - Note: Real-time form validation is handled by separate post_form_validation_controller
 */
export default class extends Controller {
  static targets = ["container"]

  /**
   * Add a new image field to the form
   */
  addImage() {
    const container = this.containerTarget
    // Unique index for the nested attributes (Rails only needs it to be unique per request)
    const newIndex = Date.now()

    const fieldHTML = `
      <div class="flex gap-3 items-end image-wrapper">
        <div class="flex-1">
          <input 
            type="file" 
            accept="image/*" 
            name="post[post_images_attributes][${newIndex}][image]" 
            class="w-full bg-slate-800/50 border border-slate-600/50 rounded-lg px-3 py-2 text-slate-100 file:mr-4 file:py-2 file:px-3 file:rounded file:border-0 file:bg-purple-600 file:text-white file:font-semibold file:cursor-pointer hover:file:bg-purple-700 transition"
          />
        </div>
        <button 
          type="button" 
          class="px-4 py-2 bg-rose-600/50 hover:bg-rose-600 text-rose-100 rounded-lg text-sm font-semibold transition flex-shrink-0" 
          data-action="click->post-form#removeImage"
          title="Remove this image"
        >
          Remove
        </button>
      </div>
    `
    
    const div = document.createElement('div')
    div.innerHTML = fieldHTML
    container.appendChild(div.firstElementChild)
  }

  /**
   * Remove an image field from the form.
   * Saved images are marked for deletion (_destroy) and hidden; new fields are removed.
   */
  removeImage(event) {
    event.preventDefault()
    const wrapper = event.target.closest('.image-wrapper')
    if (!wrapper) return

    const destroyField = wrapper.querySelector('input[name$="[_destroy]"]')
    if (destroyField) {
      destroyField.value = "1"
      wrapper.classList.add('hidden')
    } else {
      wrapper.remove()
    }
  }
}
