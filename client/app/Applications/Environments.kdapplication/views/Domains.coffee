class DomainMainView extends KDView

  constructor:(options={}, data)->
    options.cssClass or= "domains"
    data             or= {}

    @domainsListViewController = new DomainsListViewController
      viewOptions:
        tagName  : "ul"
        cssClass : "split-section-list left-section"

    @buildView()

    super options, data

    @domainsListViewController.on "domainItemClicked", @bound "decorateMapperView"

  buildView:->
    @domainsListView    = @domainsListViewController.getView()
    @domainMapperView   = new DomainMapperView
    @firewallMapperView = new FirewallMapperView
    @dnsManagerView     = new DNSManagerView

    @buildButtonsBar()

    @buildTabs()

    @splitView = new SplitViewWithOlderSiblings
      type      : "vertical"
      resizable : no
      sizes     : ["100%", null]
      views     : [@domainsListView, @tabView]

    @getSingleton("mainView").once "transitionend", =>
      @splitView._windowDidResize()

  buildTabs:->
    # Routing, Analytics, Firewall & DNS Manager Tabs
    @tabView       = new KDTabView
      cssClass     : "domain-detail-tabs"

    @routingPane   = new KDTabPaneView
      name     : "Routing"
      closable : no

    @analyticsPane = new KDTabPaneView
      name     : "Analytics"
      closable : no
      partial  : "Domain analytics will be added soon!"

    @firewallPane  = new KDTabPaneView
      name     : "Firewall"
      closable : no

    @dnsManagerPane = new KDTabPaneView
      name     : "DNS Manager"
      closable : no

    vmMapperSubView   = @domainMapperView
    kiteMapperSubView = new KDView
      partial: 'Kites are listed here.'
    kiteMapperSubView.hide()

    routingContentView = new KDCustomHTMLView
      partial: "Connect my domain to:"

    routingContentView.addSubView new KDSelectBox
      selectOptions: [{title:"VM", value:"VM"}, {title:"Kite", value:"Kite"}]
      callback: (value)->
        if value is "VM"
          vmMapperSubView.show()
          kiteMapperSubView.hide()
        else
          vmMapperSubView.hide()
          kiteMapperSubView.show()

    @routingPane.addSubView routingContentView
    @routingPane.addSubView vmMapperSubView
    @routingPane.addSubView kiteMapperSubView

    @firewallPane.addSubView @firewallMapperView

    @dnsManagerPane.addSubView @dnsManagerView

    for pane in [@routingPane, @firewallPane, @dnsManagerPane, @analyticsPane]
      @tabView.addPane pane

    @tabView.showPaneByIndex 0

  viewAppended: JView::viewAppended

  buildButtonsBar: ->
    @buttonsBar = new KDView
      cssClass  : "header"

    @buttonsBar.addSubView @addNewDomainButton = new KDButtonView
      title    : 'Add New Domain'
      cssClass        : 'editor-button new-domain-button left'
      icon            : yes
      iconClass       : 'plus'
      callback : (elm, event) =>
        @actionArea.setClass 'in'
        @buttonsBar.setClass 'out'
      #   @domainModalView = new DomainRegisterModalFormView
      #   @domainModalView.on "DomainSaved", =>
      #     @domainsListViewController.update()

    @buttonsBar.addSubView @refreshDomainsButton = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "refresh"
      loader      :
        color     : "#777777"
        diameter  : 24
      tooltip     :
        title     : "Refresh"
        placement : "left"
      callback : (elm, event)=>
        @domainsListViewController.update()

    @actionArea = new KDView cssClass : 'action-area'

    @actionArea.addSubView creationForm = new DomainCreationForm

    creationForm.on 'DomainCreationCancelled', =>
      @actionArea.unsetClass 'in'
      @buttonsBar.unsetClass 'out'

    creationForm.on 'DomainSaved', =>
      @domainsListViewController.update()

    creationForm.on 'CloseClicked', =>
      @actionArea.unsetClass 'in'
      @buttonsBar.unsetClass 'out'


  pistachio:->
    """
    {{> @buttonsBar}}
    {{> @actionArea}}
    {{> @splitView}}
    """

  decorateMapperView:(item)->
    mapperViews = [@firewallMapperView, @domainMapperView, @dnsManagerView]
    for view in mapperViews
      view.emit "domainChanged", item
    @splitView.resizePanel "300px", 0

