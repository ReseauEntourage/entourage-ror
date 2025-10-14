module NeighborhoodHelper
  def neighborhood_zone_label zone
    zone_to_class = {
      'departement'  => 'label-success',
      'ville' => 'label-info',
    }
    content_tag :span, zone, class: "label #{zone_to_class[zone] || 'label-warning' }"
  end
end
