class GoodWavesMailer < ActionMailer::Base
  def invitation email, alternate_email, group_short_uuid
    headers(
      'X-MJ-EventPayload' => JSON.fast_generate(
        type: :good_waves_invitation,
        group_uuid: "e#{group_short_uuid}"
      ),
      'X-Mailjet-Campaign' => :good_waves_invitation,
    )

    @invite_url = "http://entourage.social/i/#{group_short_uuid}"

    mail(
      from: %("Réseau Entourage" <lesbonnesondes@entourage.social>),
      to: email,
      cc: alternate_email,
      subject: "Rejoins ta bande de Bonnes Ondes sur l'app Entourage"
    )
  end
end
