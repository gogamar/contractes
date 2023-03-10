class Vrental < ApplicationRecord
  belongs_to :user
  belongs_to :vrowner, optional: true
  has_many :vragreements, dependent: :destroy
  has_many :rates, dependent: :destroy
  has_and_belongs_to_many :features
  validates :name, presence: true
  validates :status, presence: true

  def unavailable_dates
    rates.pluck(:firstnight, :lastnight).map do |range|
      { from: range[0], to: range[1] }
    end
  end

  def default_checkin
    last_rate = rates.find_by(lastnight: rates.maximum('lastnight'))
    last_rate.present? ? last_rate.lastnight + 1.day : Date.today
  end

  def copy_rates_to_next_year
    #for some reason this method doesn't work the same locally
    easter_season_firstnight = {
    2022 => Date.new(2022,4,2),
    2023 => Date.new(2023,4,1),
    2024 => Date.new(2024,3,23),
    2025 => Date.new(2025,4,12),
    2026 => Date.new(2026,3,28),
    2027 => Date.new(2027,3,20),
    2028 => Date.new(2028,4,8)
    }
    current_rates = rates.where("DATE_PART('year', firstnight) = ?", Date.today.year)
    current_rates.each do |existingrate|
    next_year = existingrate.firstnight.year + 1
      # if Easter Rate is 10 days and the rate doesn't already exist for the next year
      if easter_season_firstnight.value?(existingrate.firstnight) && (existingrate.lastnight - existingrate.firstnight).to_i == 10 && !rates.where(firstnight: easter_season_firstnight[next_year]).exists?
        Rate.create!(
          firstnight: easter_season_firstnight[next_year],
          lastnight: easter_season_firstnight[next_year] + 10,
          pricenight: existingrate.pricenight,
          priceweek: existingrate.priceweek,
          beds_room_id: existingrate.beds_room_id,
          vrental_id: existingrate.vrental_id,
          min_stay: existingrate.min_stay,
          arrival_day: existingrate.arrival_day
        )
      # if Easter rate is longer than 10 days and the rate doesn't already exist for the next year
      elsif easter_season_firstnight.value?(existingrate.firstnight) && (existingrate.lastnight - existingrate.firstnight).to_i > 10 && !rates.where(firstnight: easter_season_firstnight[next_year]).exists?
        Rate.create!(
          firstnight: easter_season_firstnight[next_year],
          lastnight: existingrate.lastnight + 364,
          pricenight: existingrate.pricenight,
          priceweek: existingrate.priceweek,
          beds_room_id: existingrate.beds_room_id,
          vrental_id: existingrate.vrental_id,
          min_stay: existingrate.min_stay,
          arrival_day: existingrate.arrival_day
        )
      # if it's Before Easter rate and the rate doesn't already exist for the next year
      elsif easter_season_firstnight.value?(existingrate.lastnight + 1) && !rates.where(lastnight: easter_season_firstnight[next_year] - 1).exists?
        Rate.create!(
          firstnight: existingrate.firstnight + 364,
          lastnight: easter_season_firstnight[next_year] - 1,
          pricenight: existingrate.pricenight,
          priceweek: existingrate.priceweek,
          beds_room_id: existingrate.beds_room_id,
          vrental_id: existingrate.vrental_id,
          min_stay: existingrate.min_stay,
          arrival_day: existingrate.arrival_day
        )
      elsif !rates.where(firstnight: existingrate.firstnight + 364).present?
        Rate.create!(
          firstnight: existingrate.firstnight + 364,
          lastnight: existingrate.lastnight + 364,
          pricenight: existingrate.pricenight,
          priceweek: existingrate.priceweek,
          beds_room_id: existingrate.beds_room_id,
          vrental_id: existingrate.vrental_id,
          min_stay: existingrate.min_stay,
          arrival_day: existingrate.arrival_day
        )
      # else
      #   return
      end
    end
  end


  def get_content_from_beds
    client = BedsHelper::Beds.new(ENV["BEDSKEY"])
    prop_key = self.prop_key
    beds24descriptions = client.get_property_content(prop_key, roomIds: true, texts: true)
    puts beds24descriptions[0]["name"]
  end

  def send_rates_to_beds
    prop_key = self.prop_key

    vrental_rates = []

    vr_rates = rates.where("firstnight > ?", Date.today).where(sent_to_beds: nil)

    vr_rates.each do |rate|

      general_rate =
        {
        action: "new",
        roomId: "#{self.beds_room_id}",
        firstNight: "#{rate.firstnight}",
        lastNight: "#{rate.lastnight}",
        name: "Tarifa #{I18n.l(rate.firstnight, format: :short)} - #{I18n.l(rate.lastnight,  format: :short)} amb 10% desc. setmanal",
        minNights: "0",
        minAdvance: "2",
        allowEnquiry: "1",
        pricesPer: "1",
        color: "#{SecureRandom.hex(3)}",
        roomPrice: "#{rate.priceweek/6.295}",
        roomPriceEnable: "1",
        roomPriceGuests: "0",
        disc1Nights: "2",
        disc2Nights: "3",
        disc3Nights: "4",
        disc4Nights: "5",
        disc5Nights: "6",
        disc6Nights: "7",
        disc7Nights: "8",
        disc8Nights: "9",
        disc6Percent: "10.00"
        }
      weekly_rate =
        {
        action: "new",
        roomId: "#{self.beds_room_id}",
        firstNight: "#{rate.firstnight}",
        lastNight: "#{rate.lastnight}",
        name: "Tarifa setmanal nom??s sistachrentals.com #{I18n.l(rate.firstnight, format: :short)} - #{I18n.l(rate.lastnight, format: :short)}",
        minAdvance: "2",
        allowEnquiry: "1",
        pricesPer: "7",
        color: "#{SecureRandom.hex(3)}",
        roomPrice: "#{rate.priceweek}",
        roomPriceEnable: "1",
        roomPriceGuests: "0",
        channel000: "1",
        channel999: "1",
        channel017: "0",
        channel046: "0",
        channel032: "0",
        channel027: "0",
        channel031: "0",
        channel052: "0",
        channel019: "0",
        channel002: "0",
        channel053: "0",
        channel059: "0",
        channel066: "0",
        channel014: "0",
        channel033: "0",
        channel012: "0",
        channel073: "0",
        channel013: "0",
        channel078: "0",
        channel044: "0",
        channel064: "0",
        channel024: "0",
        channel036: "0",
        channel057: "0",
        channel072: "0",
        channel035: "0",
        channel087: "0",
        channel051: "0",
        channel042: "0",
        channel023: "0",
        channel086: "0",
        channel050: "0",
        channel083: "0",
        channel056: "0",
        channel076: "0",
        channel055: "0",
        channel063: "0",
        channel030: "0",
        channel034: "0"
        }
        vrental_rates << general_rate
        vrental_rates << weekly_rate
    end

    auth_token = ENV["BEDSKEY"]
    client = BedsHelper::Beds.new(auth_token)
    response = client.set_rates(prop_key, setRates: vrental_rates)
    return unless response.code == 200

    vr_rates.each do |rate|
      rate.sent_to_beds = true
      rate.save!
    end
  end
end
