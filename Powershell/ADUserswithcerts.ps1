$userDets = Get-ADUser -Filter * -Properties userCertificate, displayname | Where-Object userCertificate -ne $null
$userDets | Select-Object samaccountname, enabled,lastLogonTimestamp,displayname,  @{name=”userCertificate”;expression={$_.userCertificate -join ";"}} 
#| Export-Csv -Path m:\powershell\file.csv -Force -NoTypeInformation

Set-ADUser -UserPrincipalName "Clare.Roberts@moorfields.nhs.uk" -Identity ROBERTSC
Set-ADUser -UserPrincipalName "Geoff.Rose@moorfields.nhs.uk" -Identity ROSEG
Set-ADUser -UserPrincipalName "Gayna.Winzar@moorfields.nhs.uk" -Identity WINZARG
Set-ADUser -UserPrincipalName "Mally.Scrutton@moorfields.nhs.uk" -Identity SCRUTTONM
Set-ADUser -UserPrincipalName "Denise.OMeara@moorfields.nhs.uk" -Identity DENISE
Set-ADUser -UserPrincipalName "Dan.Ehrlich@moorfields.nhs.uk" -Identity EHRLICH
Set-ADUser -UserPrincipalName "Irene.Leung@moorfields.nhs.uk" -Identity LEUNGI
Set-ADUser -UserPrincipalName "Adam.Mapani@moorfields.nhs.uk" -Identity MAPANIA
Set-ADUser -UserPrincipalName "Gill.Adams@moorfields.nhs.uk" -Identity ADAMSG
Set-ADUser -UserPrincipalName "Nazar.Yaseen@moorfields.nhs.uk" -Identity YASEENN
Set-ADUser -UserPrincipalName "Nawtej.Bhatoa@moorfields.nhs.uk" -Identity BHATOAN
Set-ADUser -UserPrincipalName "Tina.Nemeth@moorfields.nhs.uk" -Identity NEMETHC
Set-ADUser -UserPrincipalName "Francesca.Amalfitano@moorfields.nhs.uk" -Identity AMALFITANOF
Set-ADUser -UserPrincipalName "Jasmin.Singh@moorfields.nhs.uk" -Identity SINGHJ
Set-ADUser -UserPrincipalName "Rola.Alhaddad@moorfields.nhs.uk" -Identity ALHADDADR
Set-ADUser -UserPrincipalName "Marie.Barone@moorfields.nhs.uk" -Identity BARONEM
Set-ADUser -UserPrincipalName "Leigh.McEvoy@moorfields.nhs.uk" -Identity MCEVOYL
Set-ADUser -UserPrincipalName "Alexandra.Edwards@moorfields.nhs.uk" -Identity ALEXAND
Set-ADUser -UserPrincipalName "Magella.Neveu@moorfields.nhs.uk" -Identity NEVEUM
Set-ADUser -UserPrincipalName "Alison.Anscombe@moorfields.nhs.uk" -Identity ALISON
Set-ADUser -UserPrincipalName "Pari.Shams@moorfields.nhs.uk" -Identity SHAMSP
Set-ADUser -UserPrincipalName "Tom.Griggs@moorfields.nhs.uk" -Identity GRIGGST
Set-ADUser -UserPrincipalName "Samantha.Malka@moorfields.nhs.uk" -Identity LAWRENCES
Set-ADUser -UserPrincipalName "Laura.de Benito Llopis@moorfields.nhs.uk" -Identity DEBENITOLLOPISL
Set-ADUser -UserPrincipalName "Simona.Esposti@moorfields.nhs.uk" -Identity ESPOSTIS
Set-ADUser -UserPrincipalName "Alessandra.Martins@moorfields.nhs.uk" -Identity MARTINSA
Set-ADUser -UserPrincipalName "Nicoletta.Catteruccia@moorfields.nhs.uk" -Identity CATTERUCCIAN
Set-ADUser -UserPrincipalName "Lisa.Jaycocks@moorfields.nhs.uk" -Identity JAYCOCKSL
Set-ADUser -UserPrincipalName "Jackie.Oladimeji@moorfields.nhs.uk" -Identity OLADIMEJIJ
Set-ADUser -UserPrincipalName "Jenny.Gernon@moorfields.nhs.uk" -Identity GERNONJ
Set-ADUser -UserPrincipalName "Sui.Wong@moorfields.nhs.uk" -Identity WongS
Set-ADUser -UserPrincipalName "Chrissie.Gregory@moorfields.nhs.uk" -Identity GREGORYC
Set-ADUser -UserPrincipalName "Roxanne.Crosby-Nwaobi@moorfields.nhs.uk" -Identity CROSBY-NWAOBIR
Set-ADUser -UserPrincipalName "Menachem.Katz@moorfields.nhs.uk" -Identity KATZM
Set-ADUser -UserPrincipalName "Andy.Dwyer@moorfields.nhs.uk" -Identity DwyerA
Set-ADUser -UserPrincipalName "Sonia.Pavesio@moorfields.nhs.uk" -Identity PavesioS
Set-ADUser -UserPrincipalName "Neeta.Virdee@moorfields.nhs.uk" -Identity Virdeen
Set-ADUser -UserPrincipalName "Sara.EsparzaRegalado@moorfields.nhs.uk" -Identity EsparzaRegaladoS
Set-ADUser -UserPrincipalName "Selvakumar.Ramalingam@moorfields.nhs.uk" -Identity RAMALINGAMS
Set-ADUser -UserPrincipalName "Ian.Barry@moorfields.nhs.uk" -Identity BARRYI
Set-ADUser -UserPrincipalName "Jacqueline.Parkin@moorfields.nhs.uk" -Identity PARKINJ
Set-ADUser -UserPrincipalName "Lauren.Leitch-Devlin@moorfields.nhs.uk" -Identity LEITCH-DEVLINL
Set-ADUser -UserPrincipalName "Rajeev.Costa@moorfields.nhs.uk" -Identity COSTAR
Set-ADUser -UserPrincipalName "Jumoke.Adepegba@moorfields.nhs.uk" -Identity ADEPEGBAO
Set-ADUser -UserPrincipalName "Konstantina.Prapa@moorfields.nhs.uk" -Identity PRAPAK
Set-ADUser -UserPrincipalName "Daniela.Florea@moorfields.nhs.uk" -Identity FLOREAD
Set-ADUser -UserPrincipalName "Claire.Duncan@moorfields.nhs.uk" -Identity DUNCANC
Set-ADUser -UserPrincipalName "Daniela.Narvaez@moorfields.nhs.uk" -Identity NARVAEZD
Set-ADUser -UserPrincipalName "Waheeda.Malick@moorfields.nhs.uk" -Identity MALICKW
Set-ADUser -UserPrincipalName "Nicky.Bedwell@moorfields.nhs.uk" -Identity BedwellN
Set-ADUser -UserPrincipalName "Niten.Vig@moorfields.nhs.uk" -Identity VigN
Set-ADUser -UserPrincipalName "Ogechi.O'Kere@moorfields.nhs.uk" -Identity OKEREO
Set-ADUser -UserPrincipalName "Ola.Odukoya@moorfields.nhs.uk" -Identity OdukoyaO
Set-ADUser -UserPrincipalName "Annick.Fotso@moorfields.nhs.uk" -Identity FOTSOA
Set-ADUser -UserPrincipalName "Deborah.Keane@moorfields.nhs.uk" -Identity KeaneD
Set-ADUser -UserPrincipalName "Daniel.Goh@moorfields.nhs.uk" -Identity GohD2
Set-ADUser -UserPrincipalName "Brigid Ko Ying.Ning@moorfields.nhs.uk" -Identity NingB
Set-ADUser -UserPrincipalName "Kerry.Tinkler@moorfields.nhs.uk" -Identity TINKLERK
Set-ADUser -UserPrincipalName "Xia.Wu@moorfields.nhs.uk" -Identity WUX
Set-ADUser -UserPrincipalName "Alex.Winston@moorfields.nhs.uk" -Identity WinstonA
Set-ADUser -UserPrincipalName "Antonio.Calcagni@moorfields.nhs.uk" -Identity CalcagniA
Set-ADUser -UserPrincipalName "Sofia.Ajamil@moorfields.nhs.uk" -Identity AJAMILS
Set-ADUser -UserPrincipalName "Vicky.O?Connor@moorfields.nhs.uk" -Identity OConnorV
Set-ADUser -UserPrincipalName "Shaima.Guenuni@moorfields.nhs.uk" -Identity GUENUNIS

Set-ADUser -UserPrincipalName "Najiha.Rahman@moorfields.nhs.uk" -Identity RAHMANN
Set-ADUser -UserPrincipalName "Christos.Tsounis@moorfields.nhs.uk" -Identity TSOUNISC
Set-ADUser -UserPrincipalName "Muhammad.Farooqi@moorfields.nhs.uk" -Identity FAROOQIM
Set-ADUser -UserPrincipalName "Jaime.Kriman@moorfields.nhs.uk" -Identity KRIMANJ

Set-ADUser -UserPrincipalName "Sandie.Townsend@moorfields.nhs.uk" -Identity TOWNSENDS
Set-ADUser -UserPrincipalName "Tumelo.Kaminskas@moorfields.nhs.uk" -Identity KAMINSKAST
Set-ADUser -UserPrincipalName "Rasheed.Rajna@moorfields.nhs.uk" -Identity RASHEEDR
Set-ADUser -UserPrincipalName "Clare.Roebuck@moorfields.nhs.uk" -Identity ROEBUCKC
Set-ADUser -UserPrincipalName "Philipp.Mueller@moorfields.nhs.uk" -Identity MUELLERP
Set-ADUser -UserPrincipalName "Abraham.Olvera@moorfields.nhs.uk" -Identity OLVERAA
Set-ADUser -UserPrincipalName "Najiha.Rahman@moorfields.nhs.uk" -Identity RAHMANN
