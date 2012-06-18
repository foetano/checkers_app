module ApplicationHelper

  # Return a title on a per-page basis.
  def title
    base_title = "Checkers"
    if @title.nil?
      base_title
    else
      "#{base_title} | #{@title}"
    end
  end
  
  def logo
    image_tag("logo2.png")
  end
end
