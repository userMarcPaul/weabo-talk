module ApplicationHelper
  include Pagy::Frontend

  def link_to_user_mentions(text)
    # Escape the text first, so users can't add their own HTML (images, fake links, ...)
    escaped = ERB::Util.html_escape(text.to_s).to_str

    # Then turn plain URLs into links (link_to escapes the URL again)
    linked = escaped.gsub(%r{https?://[^\s<]+}) do |url|
      url = CGI.unescapeHTML(url)
      link_to(url, url, target: "_blank", rel: "noopener noreferrer", class: "text-purple-400 hover:text-purple-300 underline")
    end

    # Convert newlines to breaks; the text is already escaped
    simple_format(linked.html_safe, {}, sanitize: false)
  end
end
