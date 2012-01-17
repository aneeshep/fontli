module FeedsHelper

  def cta_button(id, val, lbl)
    content_tag(
      :button, lbl, :type => 'submit', 
      :id => (val + '_' + id), :value => val, :name => 'modal'
    )
  end
  
  def foto_classes(index)
    position = index.even? ? "float_left" : "float_right"
    rotate_count = (index % 4) + 1
    "column " + position + " rotate_" + rotate_count.to_s
  end
end
