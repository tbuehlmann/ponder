class Array
  def extract_options!
    if last.is_a?(Hash)
      pop
    else
      {}
    end
  end
end
