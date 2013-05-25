CPETitle = require '../../app/util/cpe_title'

describe 'CPE Title', ->
  it 'should generate appropriate titles', ->
    expect(CPETitle.generateTitles( \
        'a:bea:weblogic_server:6.1:sp4:express',
        'BEA Systems WebLogic Express 6.1 SP4'))
      .to.eql {
      'part': 'Application'
      'vendor': 'BEA Systems'
      'product': 'WebLogic Server'
      'version': '6.1'
      'update': 'SP4'
      'edition': 'Express'
      }
    expect(CPETitle.generateTitles( \
        'a:bea:weblogic_server:6.1:sp4:express'))
      .to.eql {
      'part': 'Application'
      'vendor': 'Bea'
      'product': 'Weblogic Server'
      'version': '6.1'
      'update': 'Sp4'
      'edition': 'Express'
      }
    expect(CPETitle.generateTitles( \
        'a:bestpractical:rt:4.0.7:rc1',
        'Best Practical Solutions RT 4.0.7 release candidate 1'))
      .to.eql {
      'part': 'Application'
      'vendor': 'Best Practical Solutions'
      'product': 'RT'
      'version': '4.0.7'
      'update': 'release candidate 1'
      }
    expect(CPETitle.generateTitles( \
        'a:bouncycastle:legion-of-the-bouncy-castle-c%23-cryptography-api:1.48'
        'Legion of the Bouncy Castle C# Cryptography API 1.48'))
      .to.eql {
      'part': 'Application'
      'vendor': 'Bouncy Castle'
      'product': 'Legion of the Bouncy Castle C# Cryptography API'
      'version': '1.48'
      }
    expect(CPETitle.generateTitles( \
        'a:compaq:foundation_agents:2.1'
        'Compaq Compaq Foundation Agents 2.1'))
      .to.eql {
      'part': 'Application'
      'vendor': 'Compaq'
      'product': 'Foundation Agents'
      'version': '2.1'
      }
    expect(CPETitle.generateTitles( \
        'a:creative_core:app_lock:1.7.5'
        'Creative Core App Lock (com.cc.applock) application for Android 1.7.5'))
      .to.eql {
      'part': 'Application'
      'vendor': 'Creative Core'
      'product': 'App Lock (com.cc.applock) application for Android'
      'version': '1.7.5'
      }
    expect(CPETitle.generateTitles( \
        'a:freso:languageicons:6.x-2.0:rc1'
        'freso Language Icons (languageicons) module for Drupal 6.x-2.0 release candidate 1'))
      .to.eql {
      'part': 'Application'
      'vendor': 'freso'
      'product': 'Language Icons (languageicons) module for Drupal'
      'version': '6.x-2.0'
      'update': 'release candidate 1'
      }
    expect(CPETitle.generateTitles( \
        'a:ibm:websphere_commerce:7.0.0.3'
        'IBM WebSphere Commerce 7.0.0.3 (Fix Pack 3)'))
      .to.eql {
      'part': 'Application'
      'vendor': 'IBM'
      'product': 'WebSphere Commerce'
      'version': '7.0.0.3 (Fix Pack 3)'
      }
    expect(CPETitle.generateTitles( \
        'a:igor_sysoev:nginx:0.5.12'
        'Nginx 0.5.13'))
      .to.eql {
      'part': 'Application'
      'vendor': 'Igor Sysoev'
      'product': 'Nginx'
      'version': '0.5.13'
      }
    expect(CPETitle.generateTitles( \
        'a:isc:dhcp:4.1-esv:r5_rc1'
        'ISC DHCP 4.1-ESV-R5rc1'))
      .to.eql {
      'part': 'Application'
      'vendor': 'ISC'
      'product': 'DHCP'
      'version': '4.1 ESV'
      'update': 'R5 rc1'
      }
    expect(CPETitle.generateTitles( \
        'a:niif:shibb_auth:5.x-1.x:dev'
        'niif Shibboleth authentication module (shib_auth) 5.x-1.x-dev'))
      .to.eql {
      'part': 'Application'
      'vendor': 'niif'
      'product': 'Shibboleth authentication module (shib_auth)'
      'version': '5.x-1.x'
      'update': 'dev'
      }
    expect(CPETitle.generateTitles( \
        'a:node_limit_number_project:node_limitnumber:6.x-2.x:dev'
        'Node Limit Number Project Node Limit Number (node_limitnumber) 6.x-2.x dev'))
      .to.eql {
      'part': 'Application'
      'vendor': 'Node Limit Number Project'
      'product': 'Node Limit Number (node_limitnumber)'
      'version': '6.x-2.x'
      'update': 'dev'
      }
    expect(CPETitle.generateTitles( \
        'a:nodewords_project:nodewords:6.x-1.12:beta9'
        'Nodewords: D6 Meta Tags module for Drupal 6.x-1.12-beta9'))
      .to.eql {
      'part': 'Application'
      'vendor': 'Nodewords Project'
      'product': 'Nodewords: D6 Meta Tags module for Drupal'
      'version': '6.x-1.12'
      'update': 'beta9'
      }
    expect(CPETitle.generateTitles( \
        'a:nordugrid:nordugrid-arc:0.3.31'
        'NorduGrid Advanced Resource Connector (ARC) 0.3.31'))
      .to.eql {
      'part': 'Application'
      'vendor': 'NorduGrid'
      'product': 'Advanced Resource Connector (ARC)'
      'version': '0.3.31'
      }
    expect(CPETitle.generateTitles( \
        'a:nvidia:gpu_driver:195.22:-:%7E%7Eesx%7E%7E%7E'
        'NVIDIA GPU Driver 195.22 for VMWare ESX'))
      .to.eql {
      'part': 'Application'
      'vendor': 'NVIDIA'
      'product': 'GPU Driver'
      'version': '195.22'
      'sw_edition': 'ESX'
      }
    expect(CPETitle.generateTitles( \
        'a:ps_project_management_team:unity-firefox-extension:0.2.1:-:%7E%7E%7Efirefox%7E%7E'
        'PS Project Management Team Unity Integration extension (unity-firefox-extension) ' +
        '0.2.1 for Firefox'))
      .to.eql {
      'part': 'Application'
      'vendor': 'PS Project Management Team'
      # Non-optimal product name, but included in test to detect variation
      'product': 'Unity firefox extension'
      'version': '0.2.1'
      'target_sw': 'Firefox'
      }
    expect(CPETitle.generateTitles( \
        'a:roderich_schupp:par-packer_module:0.87'
        'Roderich Schupp PAR::Packer (Par-Packer) module 0.87'))
      .to.eql {
      'part': 'Application'
      'vendor': 'Roderich Schupp'
      # Non-optimal product name, but included in test to detect variation
      'product': 'PAR Packer module'
      'version': '0.87'
      }
    expect(CPETitle.generateTitles( \
        'a:siemens:scalance_x-300eec_firmware:3.7.0'
        'Siemens Scalance X Industrial Ethernet switch X-300-EEC firmware 3.7.0'))
      .to.eql {
      'part': 'Application'
      'vendor': 'Siemens'
      # Non-optimal product name, but included in test to detect variation
      'product': 'Scalance X 300 EEC firmware'
      'version': '3.7.0'
      }

  it 'should generate titles by ancestry', ->
    expect(CPETitle.generateTitlesByAncestry {
      part: 'a'
      vendor: 'vendor'
      product: 'product'
      version: 'version'
      update: 'update'
      edition: 'edition'
      lang: 'lang'
      sw_edition: 'sw_edition'
      target_sw: 'target_sw'
      target_hw: 'target_hw'
      other: 'other'
    }, 'Vendor Product Version Update Edition Language SW_Edition Target_SW Target_HW Other')
    .to.eql([
      {
        id: 'a'
        title: 'Application'
      }
      {
        id: 'a:vendor'
        title: 'Vendor'
      }
      {
        id: 'a:vendor:product'
        title: 'Product'
      }
      {
        id: 'a:vendor:product:version'
        title: 'Version'
      }
      {
        id: 'a:vendor:product:version:update'
        title: 'Update'
      }
      {
        id: 'a:vendor:product:version:update:edition'
        title: 'Edition'
      }
      {
        id: 'a:vendor:product:version:update:edition:lang'
        title: 'Language'
      }
      {
        id: 'a:vendor:product:version:update:~edition~sw_edition~~~:lang'
        title: 'SW_Edition'
      }
      {
        id: 'a:vendor:product:version:update:~edition~sw_edition~target_sw~~:lang'
        title: 'Target_SW'
      }
      {
        id: 'a:vendor:product:version:update:~edition~sw_edition~target_sw~target_hw~:lang'
        title: 'Target_HW'
      }
      {
        id: 'a:vendor:product:version:update:~edition~sw_edition~target_sw~target_hw~other:lang'
        title: 'Other'
      }
    ])
    expect(CPETitle.generateTitlesByAncestry {
      part: 'a'
      vendor: 'vendor'
      product: 'product'
      version: 'version'
      sw_edition: 'sw_edition'
    }, 'Vendor Product Version SW_Edition')
    .to.eql([
      {
        id: 'a'
        title: 'Application'
      }
      {
        id: 'a:vendor'
        title: 'Vendor'
      }
      {
        id: 'a:vendor:product'
        title: 'Product'
      }
      {
        id: 'a:vendor:product:version'
        title: 'Version'
      }
      {
        id: 'a:vendor:product:version::~~sw_edition~~~'
        title: 'SW_Edition'
      }
    ])