class ContractsController < ApplicationController
  require 'date'
  before_action :set_contract, only: [:show, :edit, :update, :destroy, :preview, :purge_photo]
  before_action :set_realestate, only: [ :new, :create, :edit, :update ]

  def index
    all_contracts = policy_scope(Contract)
    @pagy, @contracts = pagy(all_contracts, page: params[:page], items: 10)
  end

  def list
    @contracts = policy_scope(Contract).includes(:realestate)
    @contracts = @contracts.where("DATE_PART('year', signdate) = ?", params[:year]) if params[:year].present?
    @contracts = @contracts.where(realestate_id: params[:realestate_id]) if params[:realestate_id].present?
    @contracts = @contracts.order("#{params[:column]} #{params[:direction]}")
    @pagy, @contracts = pagy(@contracts, page: params[:page], items: 10)
    render(partial: 'contracts', locals: { contracts: @contracts })
  end

  def show
    authorize @contract
    @rstemplates = Rstemplate.all
    @contracts = Contract.all
    @seller = @contract.realestate.seller
    @buyer = @contract.buyer
    @realestate = @contract.realestate
    @rstemplate = @contract.rstemplate
    @addendums = []
    @addendums << @contract.registry_addendum if @contract.registry_addendum.attached?
    @addendums << @contract.habitability_addendum if @contract.habitability_addendum.attached?
    @addendums << @contract.energy_addendum if @contract.energy_addendum.attached?
    @addendums << @contract.equipment_addendum if @contract.equipment_addendum.attached?
    @addendums << @contract.addendums if @contract.addendums.attached?

    details = {
      num_aicat: current_profile.aicat.present? ? current_profile.aicat : '',
      num_api: current_profile.api.present? ? current_profile.api : '',
      data_firma: @contract.signdate.present? ? l(@contract.signdate, format: :long).to_s : '',
      lloc_firma: @contract.place.present? ? @contract.place : '',
      preu: @contract.price.present? ? format("%.2f",@contract.price) : '',
      preu_text: @contract.pricetext.present? ? @contract.pricetext.upcase : '',
      clausula_adicional: @contract.contentarea.to_s,
      venedor: @realestate.seller.present? && @realestate.seller.fullname.present? ? @realestate.seller.fullname : '',
      dni_venedor: @realestate.seller.present? && @realestate.seller.document.present? ? @realestate.seller.document : '',
      adr_venedor: @realestate.seller.present? && @realestate.seller.address.present? ? @realestate.seller.address : '',
      email_venedor: @realestate.seller.present? && @realestate.seller.email.present? ? @realestate.seller.email : '',
      tel_venedor: @realestate.seller.present? && @realestate.seller.phone.present? ? @realestate.seller.phone : '',
      compte_venedor:
        if @realestate.seller && @realestate.seller.account.empty?
          "<a href='#{edit_seller_url(@realestate.seller)}' class='text-danger' target='_blank'>***Falta el compte del venedor***</a>"
        elsif @realestate.seller && @realestate.seller.account
          @realestate.seller.account
        else
          "<a href='#{edit_realestate_url(@realestate)}' class='text-danger' target='_blank'>***Afegir Venedor***</a>"
        end,
      banc_venedor:
        if @realestate.seller && @realestate.seller.account_bank.empty?
          "<a href='#{edit_seller_url(@realestate.seller)}' class='text-danger' target='_blank'>***Falta el nom del banc del venedor***</a>"
        elsif @realestate.seller && @realestate.seller.account_bank
          @realestate.seller.account_bank
        else
          "<a href='#{edit_realestate_url(@realestate)}' class='text-danger' target='_blank'>***Afegir Venedor***</a>"
        end,
      comprador: @contract.buyer.present? ? @contract.buyer.fullname : "<a href='#{edit_contract_url(@contract)}' class='text-danger' target='_blank'>***Afegir comprador***</a>",
      dni_comprador:
        if @contract.buyer && @contract.buyer.document.empty?
          "<a href=#{edit_buyer_url(@contract.buyer)} class='text-danger' target='_blank' >***Falta el dni del comprador***</a>"

        elsif @contract.buyer && @contract.buyer.document
          @contract.buyer.document
        else
          "<a href='#{edit_contract_url(@contract)}' class='text-danger' target='_blank'>***Afegir Comprador***</a>"
        end,
      adr_comprador: @contract.buyer.present? && @contract.buyer.address.present? ? @contract.buyer.address : '',
      email_comprador: @contract.buyer.present? && @contract.buyer.email.present? ? @contract.buyer.email : '',
      tel_comprador: @contract.buyer.present? && @contract.buyer.phone.present? ? @contract.buyer.phone : '',
      compte_comprador: @contract.buyer.present? && @contract.buyer.account.present? ? @contract.buyer.account : '',
      banc_comprador: @contract.buyer.present? && @contract.buyer.account_bank.present? ? @contract.seller.account_bank : '',
      adr_immoble: @realestate.address.present? ? @realestate.address : '',
      poblacio_immoble: @realestate.city.present? ? @realestate.city : '',
      cadastre: @realestate.cadastre.present? ? @realestate.cadastre : '',
      cert_energetic: @realestate.energy.present? ? @realestate.energy : '',
      descripcio: @realestate.description.present? ? @realestate.description : '',
      pantallazo_descripcio: @realestate.description_screenshot.present? ? "<img src='#{@realestate.description_screenshot.url}'>" : '',
      oficina_registre: @realestate.registrar.present? ? @realestate.registrar : '',
      codi_cru: @realestate.registry_code.present? ? @realestate.registry_code : '',
      tom: @realestate.volume.present? ? @realestate.volume : '',
      llibre: @realestate.book.present? ? @realestate.book : '',
      foli: @realestate.sheet.present? ? @realestate.sheet : '',
      num_finca_registre: @realestate.registry.present? ? @realestate.registry : '',
      inscripcio: @realestate.entry.present? ? @realestate.entry : '',
      carregues: @realestate.charges.present? ? @realestate.charges : '',
      pantallazo_carregues: @realestate.charges_screenshot.present? ? "<img src='#{@realestate.charges_screenshot.url}'>" : '',
      num_protocol: @realestate.protocol.present? ? @realestate.protocol : '',
      data_escriptura: @realestate.deed_date.present? ? l(@realestate.deed_date, format: :long).to_s : '',
      notaria_escriptura: @realestate.notary.present? ? @realestate.notary : '',
      notari_escriptura: @realestate.notary_fullname.present? ? @realestate.notary_fullname : '',
      banc_hipoteca: @realestate.mortgage_bank.present? ? @realestate.mortgage_bank : '',
      import_hipoteca: @realestate.mortgage_amount.present? ? @realestate.mortgage_amount : '',
      cedula: @realestate.habitability.present? ? @realestate.habitability : '',
      data_cedula: @realestate.hab_date.present? ? l(@realestate.hab_date, format: :long).to_s : '',
      import_arres: @contract.down_payment.present? ? format("%.2f", @contract.down_payment) : '',
      import_arres_text: @contract.down_payment_text.present? ? @contract.down_payment_text.upcase : '',
      arres_primer_pagament: @contract.dp_part1.present? ? format("%.2f", @contract.dp_part1) : '',
      arres_primer_pagament_text: @contract.dp_part1_text.present? ? @contract.dp_part1_text.upcase : '',
      arres_segon_pagament: @contract.dp_part2.present? ? format("%.2f", @contract.dp_part2) : '',
      arres_segon_pagament_text: @contract.dp_part2_text.present? ? @contract.dp_part2_text.upcase : '',
      data_firma_notaria: @contract.signdate_notary.present? ? l(@contract.signdate_notary, format: :long) : '',
      preavis_minim: @contract.min_notice.present? ? @contract.min_notice : '',
      jutjat: @contract.court.present? ? @contract.court : '',
      annexos: @addendums.empty? ? '' : @contract.extract_annexos.join,
      num_annex_nota_simple: @contract.registry_addendum.attached? ? (@addendums.index{|x| x.name == "registry_addendum"} + 1).to_s : '',
      num_annex_cedula: @contract.habitability_addendum.attached? ? (@addendums.index{|x| x.name == "habitability_addendum"} + 1).to_s : '',
      num_annex_cert_energetic: @contract.energy_addendum.attached? ? (@addendums.index{|x| x.name == "energy_addendum"} + 1).to_s : '',
      num_annex_equipament: @contract.equipment_addendum.attached? ? (@addendums.index{|x| x.name == "equipment_addendum"} + 1).to_s : '',
    }

    body = @rstemplate.text.to_s

    @rscontrato = Contract.parse_template(body, details)

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: [@realestate.address, @seller].join('-'), # filename: "Posts: #{@posts.count}"
          template: "contracts/show",
          formats: [:html],
          disposition: :inline,
          page_size: 'A4',
          dpi: '75',
          zoom: 1,
          layout: 'pdf',
          margin:  {   top:    10,
                        bottom: 20,
                        left:   15,
                        right:  15},
          footer: { right: "#{t("page")} [page] #{t("of")} [topage]", center: @contract.signdate.present? ? l(@contract.signdate, format: :long) : '', font_size: 8, spacing: 5}
      end
    end
  end

  def new
    @contract = Contract.new
    authorize @contract
    @rstemplates = policy_scope(Rstemplate)
  end

  def edit
    authorize @contract
    @rstemplates = policy_scope(Rstemplate)
  end

  def create
    @contract = Contract.new(contract_params)
    @contract.realestate = @realestate
    authorize @contract
    if @contract.save
      redirect_to @contract, notice: "Has creat el contracte per a #{@realestate.address}."
    else
      render :new
    end
  end

  def update
    @contract.realestate = @realestate
    authorize @contract
    if @contract.update(contract_params)
      redirect_to @contract, notice: 'Has actualitzat el contracte.'
    else
      render :edit
    end
  end

  def destroy
    authorize @contract
    @contract.destroy
    redirect_to contracts_url, notice: "Has esborrat el contracte del #{@contract.realestate.address}."
  end

  private

  def set_contract
    @contract = Contract.find(params[:id])
  end

  def set_realestate
    @realestate = Realestate.find(params[:realestate_id])
  end

  def contract_params
    params.require(:contract).permit(:signdate, :place, :price, :pricetext, :down_payment, :down_payment_text, :realestate_id, :buyer_id, :rstemplate_id, :dp_part1, :dp_part1_text, :dp_part2, :dp_part2_text, :signdate_notary, :min_notice, :court, :contentarea, :registry_addendum, :habitability_addendum, :energy_addendum, :equipment_addendum, photos: [], addendums: [])
  end
end
