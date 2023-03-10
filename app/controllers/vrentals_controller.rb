class VrentalsController < ApplicationController
  before_action :set_vrental, only: [:show, :edit, :update, :destroy, :copy_rates, :send_rates]

  def index
    all_vrentals = policy_scope(Vrental)
    @pagy, @vrentals = pagy(all_vrentals, page: params[:page], items: 10)
    # @vrentals = Vrental.all.sort_by(&:created_at).reverse
  end

  def list
    @vrentals = policy_scope(Vrental).includes(:vrowner)
    @vrentals = @vrentals.where('unaccent(name) ILIKE ?', "%#{params[:name]}%") if params[:name].present?
    @vrentals = @vrentals.where(status: params[:status]) if params[:status].present?
    @vrentals = @vrentals.order("#{params[:column]} #{params[:direction]}")
    @pagy, @vrentals = pagy(@vrentals, page: params[:page], items: 10)
    render(partial: 'vrentals', locals: { vrentals: @vrentals })
  end

  def show
    authorize @vrental
    @rate = Rate.new
    @rates = policy_scope(Rate)
    @rates = Rate.where(vrental_id: @vrental).order(firstnight: :asc)
    @features = policy_scope(Feature)
    @features = Feature.all
    @years = [Date.today.next_year.year, Date.today.year, Date.today.last_year.year]
  end

  def new
    @vrental = Vrental.new
    authorize @vrental
    @vrentals = Vrental.all.sort_by(&:name)
  end

  # GET /products/1/copy
  def copy
    @source = Vrental.find(params[:id])
    @vrental = @source.dup
    @vrental.name = "#{@vrental.name} CÒPIA"
    @vrental.rates = []
    @source.rates.each { |rate| @vrental.rates << rate.dup }
    @vrental.features = []
    # instead of duplicating features, the same features need to be assigned to the new record
    @source.features.each { |feature| @vrental.features << feature }
    authorize @vrental
    @vrental.save!
    redirect_to @vrental, notice: "S'ha creat una còpia de l'immoble: #{@vrental.name}."
  end

  def copy_rates
    @vrental.copy_rates_to_next_year
    authorize @vrental
    redirect_to @vrental, notice: "Les tarifes ja estàn copiades."
  end

  def send_rates
    @vrental.send_rates_to_beds
    authorize @vrental
    redirect_to @vrental, notice: "Les tarifes ja estàn enviades."
  end

  def edit
    @feature_list = Feature.all.uniq
    authorize @vrental
  end


  def create
    @vrental = Vrental.new(vrental_params)
    @vrental.user_id = current_user.id
    authorize @vrental
    if @vrental.save
      redirect_to vrentals_path, notice: 'Has creat un nou immoble.'
    else
      render :new, status: :unprocessable_entity
    end
  end


  def update
    authorize @vrental
    if @vrental.update(vrental_params)
      redirect_to vrentals_path, notice: 'S\'ha modificat l\'immoble.'
    else
      render :edit, status: :unprocessable_entity
    end
  end


  def destroy
    authorize @vrental
    @vrental.destroy
    redirect_to vrentals_url, notice: 'S\'ha esborrat l\'immoble.'
  end


  private

  def set_vrental
    @vrental = Vrental.find(params[:id])
  end

  def vrental_params
    params.require(:vrental).permit(:name, :address, :licence, :cadastre, :habitability, :commission, :beds_prop_id, :beds_room_id, :prop_key, :vrowner_id, :max_guests, :description, :description_es, :description_fr, :description_en, :status, feature_ids:[])
  end
end
