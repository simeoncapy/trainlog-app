# General

Ang application ay nahahati sa apat na pangunahing bahagi: ang **mapa**, ang **listahan ng biyahe**, ang **leaderboard** at ang **istatistika**. Ang mga ito ay maa-access gamit ang navigation bar sa ibaba. Ang iba pang mga functionnalite ay matatagpuan sa loob ng main menu. Maaari mo itong buksan gamit ang floating burger icon :icon(menu): sa itaas na kaliwa.

# Mapa

Ipinapakita ng mapa ang lahat ng iyong dinaanang ruta. Ang mga kulay ay depende sa transportation mode (maaari mong palitan ang paleta ng kulay sa settings). Ang isang nakaiskedyul na biyahe ay ipapakita nang may hatching, at ang isang kasalukuyang biyahe ay kukulayan ng pula. May iba't ibang mga filter na magagamit upang magpakita ng mga partikular na biyahe, i-click lamang ang button sa kanang ibaba.

Bukod dito, tatlong tool ang magagamit upang pamahalaan ang mapa. Ang una :icon(my_location): ay muling igigitna ang mapa sa iyong kasalukuyang posisyon (kung pinayagan mo ang Trainlog na i-access ito), at ang double tap ay magre-reset ng zoom value. Ang pangalawang opsyon ay awtomatikong igigitna ang mapa sa iyong posisyon habang gumagalaw, i-tap ang :sym(frame_person): upang i-activate ito, at :sym(frame_person_off): upang i-disable ito. Ang huli :icon(explore): ay muling ituturo ang mapa sa Hilaga.

Maaari mong i-click ang anumang path upang magpakita ng summary sheet ng iyong biyahe. Mula dito maaari mong i-share, i-edit, i-duplicate at i-delete ang iyong biyahe. Tungkol sa opsyon sa pagbabahagi, kailangan mong i-enable ito sa settings. Ang biyahe ay ibabahagi bilang isang link.

# Listahan ng biyahe

Ipapakita nito ang lahat ng iyong mga biyahe, nakaraan at hinaharap (gamitin ang toggle selector sa itaas), sa isang paginated view. Maaari kang mag-scroll nang pahalang sa table upang magpakita ng higit pang impormasyon tungkol sa iyong mga biyahe. Upang ipakita ang lahat ng mga detalye, i-click ang isang hilera upang ipakita ang bottom sheet. Kung i-drag mo pababa ang table, ire-refresh nito ang iyong listahan ng biyahe mula sa server.

## Magdagdag ng biyahe - basics

Piliin muna ang uri ng sasakyan na iyong ginamit, dahil may epekto ito sa paghahanap ng istasyon. Maaari mo ring piliin ang mga istasyon sa pamamagitan ng paglalagay ng pangalan nito. Ang isang minimap ay maaaring magamit upang suriin kung ang napiling seleksyon ay tama o hindi. Ito ay lalong kapaki-pakinabang kapag ang isang malaking istasyon ay nahahati sa iba't ibang entity (may suffix na mga letra). Maaari mong palakihin ang minimap sa pamamagitan ng pag-click sa :icon(fullscreen):.

Sakaling hindi umiiral ang istasyon, maaari kang gumawa ng manual station. Para dito, i-click ang :sym(globe_location_pin): upang baguhin ang mode. Pagkatapos ay ilagay ang pangalan ng istasyon at ang mga coordinate nito. Kung hindi mo alam ang mga coordinate, maaari mo ring ilipat ang pin sa minimap pagkatapos itong palakihin.

Sa dulo ng form, maaari kang pumili ng isa o ilang mga operator para sa mga biyahe. Lalabas ang mga dati nang umiiral. Sakaling hindi umiiral ang operator, maaari mong i-validate ang field gamit ang enter o isang kuwit upang gumawa ng operator na walang logo. Maaari mong hilingin na idagdag ang logo sa app sa Discord ng proyekto (tingnan ang Trainlog tab).

## Magdagdag ng biyahe - dates

Tatlong date mode ang available, mapipili sa itaas ng screen:

- **Precise**: Ilagay ang eksaktong mga petsa at oras ng pag-alis at pagdating. Ang parehong mga field ay may kasamang date picker at time picker. Ang timezone ay awtomatikong kinukuha mula sa station coordinates at ipinapakita sa ibaba ng bawat field ng oras. Maaari mo ring irecord ang aktwal na delay sa pamamagitan ng pag-expand ng delay section: ilagay ang delay sa minuto, o direktang itakda ang aktwal na oras ng pag-alis/pagdating.
- **Date**: Ilagay lamang ang petsa ng paglalakbay (nang walang oras). Maaari mong opsyonal na tukuyin ang tagal ng biyahe sa mga oras at minuto.
- **Unknown**: Gamitin ito kapag hindi mo alam ang eksaktong petsa. Piliin kung ang biyahe ay sa nakaraan o sa hinaharap, at opsyonal na maglagay ng tinatayang tagal.

## Magdagdag ng biyahe - details

Ang lahat ng mga field sa pahinang ito ay opsyonal.

Maaari mong punan ang numero o pangalan ng **line**, ang **material** (rolling stock model), ang **registration** number ng sasakyan, ang iyong **seat** number, at isang free-text na **note**.

Hinahayaan ka ng section na **Ticket** na irecord ang presyo ng tiket (may currency picker) at ang petsa ng pagbili.

Hinahayaan ka ng section na **Energy** na tukuyin ang traction type ng sasakyan: auto, electric, o fuel.

Ang section na **Visibility** ay kumokontrol kung sino ang makakakita sa biyaheng ito: private (ikaw lang), friends lang, o public.

## Magdagdag ng biyahe - path

Ang path step ay nagpapakita ng isang interactive na mapa na awtomatikong kinukuwenta ang ruta sa pagitan ng iyong mga istasyon ng pag-alis at pagdating. Ang distansya at tinatayang tagal ay ipinapakita sa itaas. Para sa mga biyahe sa tren, metro, at tram, maaari mong i-toggle ang **new router** na opsyon upang gumamit ng alternatibong routing engine — i-tap ang help icon para sa higit pang mga detalye. Kapag nasiyahan ka na sa path, pindutin ang **Validate** upang i-save ang biyahe. Maaari mo ring pindutin ang **Continue trip** upang i-save at agad na magsimula ng isang bagong biyahe gamit ang kasalukuyang arrival station bilang bagong departure.

# Ranking

Ang pahina ng ranking ay nagpapakita ng leaderboard ng lahat ng mga gumagamit ng Trainlog para sa bawat kategorya ng sasakyan.

# Istatistika

Hinahayaan ka ng pahina ng istatistika na galugarin ang iyong data sa paglalakbay sa pamamagitan ng mga chart at table. Gamitin ang filter panel sa itaas upang i-customize ang view — i-tap ito upang i-expand o i-collapse.

Ang mga available na filter ay:
- **Vehicle**: ang uri ng transportasyon na susuriin.
- **Year**: i-filter ayon sa isang partikular na taon, o piliin ang "Lahat ng mga taon" para sa buong kasaysayan. (Disabled kapag ang graph type ay nakatakda sa "Years".)
- **Graph type**: piliin kung saan hahati-hatiin ang data — operator, bansa, mga taon, materyal, o itinerary.
- **Unit**: piliin ang metric — bilang ng mga biyahe, distansya, tagal, o CO2.

Tatlong uri ng chart ang available sa pamamagitan ng selector sa kanang sulok sa itaas:
- **Bar chart**: nagpapakita ng nangungunang 10 entry bilang isang bar chart. Hinahayaan ka ng isang toggle na magpalipat-lipat sa horizontal at vertical orientations.
- **Pie chart**: nagpapakita ng nangungunang 10 entry bilang isang pie chart.
- **Table**: nagpapakita ng buong dataset bilang isang sortable table, na may magkahiwalay na column para sa nakaraan at hinaharap na mga biyahe. Hinahayaan ka ng isang toggle na magpalipat-lipat sa pagitan ng pag-uuri ayon sa kabuuang halaga at pagkakasunod-sunod ng alpabeto.

Ang parehong nakaraan at hinaharap na mga biyahe ay ipinapakita nang magkatabi sa lahat ng uri ng chart.

# Geolog (Smart Prerecorder)

Ang Geolog ay isang smart pre-recorder na naa-access mula sa main menu. Hinahayaan ka nitong irecord ang iyong kasalukuyang lokasyon sa sandali ng pag-alis at pagdating, pagkatapos ay gamitin ang dalawang record na iyon upang awtomatikong gumawa ng biyahe.

I-tap ang **Record** button upang i-save ang isang geolog. Kukuhanin ng app ang iyong kasalukuyang coordinates at timestamp, pagkatapos ay hahanapin ang pinakamalapit na istasyon sa loob ng na-configure na radius (maaaring i-adjust sa settings). Kung maraming istasyon ang nahanap sa malapit, isang dialog ng pagpili ang lalabas upang mapili mo ang tama. Kung walang nahanap na istasyon, ang geolog ay mase-save na may hindi alam na lokasyon. Ang lahat ng data ay nakaimbak nang lokal sa iyong device lamang.

Upang gumawa ng biyahe, pumili ng eksaktong dalawang geolog mula sa listahan — ang una ay ituturing bilang departure (may markang **D**) at ang pangalawa bilang arrival (may markang **A**). Pagkatapos ay i-tap ang **Create a trip** upang buksan ang add trip form na may paunang punong mga lokasyon at timestamp. Matapos ma-save ang biyahe, ang dalawang geolog ay awtomatikong tatanggalin.

Maaari mong tanggalin ang mga indibidwal na geolog sa pamamagitan ng pagpili sa mga ito at pag-tap sa **Delete selection**, o alisin ang lahat ng mga ito nang sabay-sabay gamit ang **Delete all**. Ang sort order (pinakabago/pinakaluma muna) ay maaaring i-toggle gamit ang sort button.