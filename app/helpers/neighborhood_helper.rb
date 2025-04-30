module NeighborhoodHelper
  def neighborhood_zone_label zone
    zone ||= "theme"

    zone_to_class = {
      'departement'  => 'label-success',
      'ville' => 'label-info',
      'theme' => 'label-warning',
    }
    content_tag :span, zone, class: "label #{zone_to_class[zone]}"
  end
end
