PROGRAM projet_gestion_hotel;

USES crt, dos;

              {----------   DEFINITION DES TYPES   ----------}

TYPE

    tdate = record
                  jour,mois,annee:integer;
            end;

    tinfo = record
                  nom:string[30];
                  nbre_niv,nbre_chambre:integer;
                  date_debut:tdate;
                  adresse:string;
                  tel:string[20];
            end;

    tclient = record
                    tel:string[20];
                    nom:string[10];
                    prenom:string[20];
                    classe:char;
                    num_chambre:string[5];
                    date_reser:tdate;
                    date_entree:tdate;
                    nuite:integer;
                    date_sortie:tdate;
                    tarif_spe,pti_dej,phone,bar:boolean;
                    tarif_chambre,tarif_pti_dej,tarif_phone,tarif_bar,total:real;
              end;

    tchambre = record
                     num:string[5];
                     classe:char;
                     etat:char;
               end;

    treservation = tclient;

    tcategorie = record
                       classe:string[20];
                       tarif_normal,tarif_special:real;
                 end;

    tser_annexes = record
                         nom:string[30];
                         tarif:real;
                   end;

    tfacture = tclient;

    tconf = record
                  couleur_fond,
                  couleur_select,
                  couleur_text_fond,
                  couleur_text_select,
                  couleur_bas,
                  couleur_text_bas : word
            end;

    ttableau = array [1..10] of string;

             {----------   DEFINITION DES VARIABLES   ----------}
var

     {les fichiers}

   finfo : file of tinfo;
   fclient : file of tclient;
   fchambre : file of tchambre;
   fcategorie : file of tcategorie;
   fser_annexes : file of tser_annexes;
   ffacture : file of tfacture;
   fconf : file of tconf;

     {les autres variables}

   vinfo : tinfo;
   vclient : tclient;
   vchambre : tchambre;
   vreservation : treservation;
   vcategorie : tcategorie;
   vser_annexes : tser_annexes;
   vfacture : tfacture;
   vconf : tconf;

   ch:char;

           {----------   LES PROCEDURES ET FONCTIONS   ----------}

     {verifie si le numero de telephone est valide}

function valide_phone(tel:string):boolean;
var ok:boolean;
    i:integer;
begin
     i:=0;
     ok:=true;
     while (i<length(tel)) and ok do
     begin
          inc(i);
          ok:=tel[i] in ['0'..'9',' ','.','-'];
     end;
     valide_phone:=ok;
end;

     {trace un rectangle}

procedure rect(a,b,c,d:integer);
var i:integer;
begin
     for i:=a to c do
     begin
          gotoxy(i,b); write(#205);
          gotoxy(i,d); write(#205);
     end;
     for i:=b to d do
     begin
          gotoxy(a,i); write(#186);
          gotoxy(c,i); write(#186);
     end;
     gotoxy(a,b); write(#201);
     gotoxy(c,b); write(#187);
     gotoxy(a,d); write(#200);
     gotoxy(c,d); write(#188);
end;

     {verifie si une annee est bissex}

function bissex(an:integer):boolean;
begin
     bissex:=(an mod 100<>0) and (an mod 4=0) or (an mod 100=0) and (an mod 400=0);
end;

     {ecris une date que l'on lui a transmis}

procedure ecris_date(date:tdate);
begin
     write(date.jour:2,'-',date.mois,'-',date.annee);
end;

     {verifie si une date est valide}

function valide_date(date:tdate):boolean;
var ok:boolean;
begin
     with date do
     begin
          ok:=(mois in[1,3,5,7,8,10,12]) and (jour in [1..31]);
          ok:=ok or (mois in [4,6,9,11]) and (jour in [1..30]);
          ok:=ok or (mois=2) and (bissex(annee) and (jour in [1..29]) or (not bissex(annee)) and (jour in [1..28]));
          ok:=ok and (mois in [1..12]);
     end;
     valide_date:=ok;
end;

     {affecte a la variable date de type tdate la date en cours}

procedure today(var date:tdate);
var an,mo,jo,a:word;
begin
     getdate(an,mo,jo,a);
     date.jour:=jo;
     date.mois:=mo;
     date.annee:=an;
end;

     {ajouter n jours sur une date}

procedure date_plus(date1:tdate;n:integer;var date2:tdate);
var a:integer;
begin
     date2:=date1;
     for a:=1 to n do
     begin
          inc(date2.jour);
          if not valide_date(date2) then
             begin
                  date2.jour:=1;
                  inc(date2.mois);
                  if not valide_date(date2) then
                     begin
                          date2.mois:=1;
                          inc(date2.annee);
                     end;
             end;
     end;
end;

     {comparaison de deux dates}

function sup_date(date1,date2:tdate):boolean;
var ok:boolean;
begin
     ok:= date1.annee > date2.annee;
     ok:= ok or (date1.annee = date2.annee) and (date1.mois > date2.mois);
     ok:= ok or (date1.annee = date2.annee) and (date1.mois = date2.mois) and (date1.jour > date2.jour);
     sup_date:=ok;
end;

function sous_date(date1,date2:tdate):integer;
var i:integer;
begin
     i:=0;
     if sup_date(date1,date2) then
     begin
          repeat
                date_plus(date2,1,date2);
                inc(i);
          until not sup_date(date1,date2);
     end;
     sous_date:=i;
end;

     {ecris la date}

procedure date;
var a,m,j,jj:word;
begin
     getdate(a,m,j,jj);
     case jj of 1:write(' LUNDI ');  2:write(' MARDI ');     3:write(' MERCREDI ');
                4:write(' JEUDI ');  5:write(' VENDREDI ');  6:write(' SAMEDI ');
                0:write(' DIMANCHE ');end;
     write(j:2,'-',m:2,'-',a:4);
end;

    {ecris l'heure}

procedure heur;
var h,m,s,t:word;
begin
     gettime(h,m,s,t);
     write(h:2,':',m:2,':',s:2);
end;

     {cette procedure permet de creer automatiquement les factures des clients qui doivent sortir, de les supprimer du fichier
       client ou bien de supprimer les reservations des clients qui viennent aujourd'hui;
			donc il doit modifier l'etat d'une chambre qui peut passer de reverve a occupe ou de occupe a libre}

procedure generation;
type table_client = array[1..500] of tclient;
var tab_cli:^table_client;
    i,compteur:integer;
    date:tdate;
begin
     new(tab_cli);
     reset(ffacture);
     seek(ffacture,filesize(ffacture));
     compteur:=0;
     today(date);
     reset(fclient);
     while not eof(fclient) do
     begin
          inc(compteur);
          read(fclient,vclient);
          tab_cli^[compteur]:=vclient;
          if not sup_date(vclient.date_entree,date) then
          begin
               reset(fchambre);
               i:=-1;
               repeat
                     read(fchambre,vchambre);
                     inc(i);
               until (vchambre.num=tab_cli^[compteur].num_chambre) or eof(fchambre);
               seek(fchambre,i);
               vchambre.etat:='O';
               write(fchambre,vchambre);
               close(fchambre);
          end;
          if not sup_date(vclient.date_sortie,date) then
          begin
               write(ffacture,vclient);
               reset(fchambre);
               i:=-1;
               repeat
                     read(fchambre,vchambre);
                     inc(i);
               until (vchambre.num=tab_cli^[compteur].num_chambre) or eof(fchambre);
               seek(fchambre,i);
               vchambre.etat:='L';
               write(fchambre,vchambre);
               close(fchambre);
               tab_cli^[compteur].num_chambre:='*****';
          end;
     end;
     rewrite(fclient);
     for i:=1 to compteur do
         if tab_cli^[i].num_chambre<>'*****' then
            write(fclient,tab_cli^[i]);
     close(fclient);
     dispose(tab_cli);
end;

   {efface l'ecran en ecrivant le titre de la page, les auteurs, la date en cours et le nom de l'hotel}

procedure efface(titre:string);
var erreur,x:integer;
begin
     textcolor(vconf.couleur_text_fond);
     textbackground(vconf.couleur_fond);
     clrscr;
     window(1,46,80,50);
     textbackground(vconf.couleur_bas);
     clrscr;
     textbackground(vconf.couleur_fond);
     window(1,1,80,50);
     rect(2,2,79,6);
     gotoxy((80-length(titre)) div 2,4);write(titre);
     textcolor(vconf.couleur_text_bas);
     for x:=1 to 80 do
     begin
          gotoxy(x,46);
          write(#219);
     end;
     {$I-}
          reset(finfo);
     {$I+}
     erreur:=ioresult;
     if (erreur=0) and (filesize(finfo)<>0) then
     begin
          read(finfo,vinfo);
          close(finfo);
     end;
     textbackground(vconf.couleur_bas);
     gotoxy(2,48);write('HOTEL : ',vinfo.nom);
     gotoxy(60,48);date;
     gotoxy(9,50);write('CHEIKH SIDYA CAMARA  *  MARIUS GANA NDIAYE  *  KHADIDIATOU KANE');
     textbackground(vconf.couleur_fond);
     textcolor(vconf.couleur_text_fond);
end;

     {c'est une fonction qui donne l'indices des elements selectionnes du menu}

function bouge(k,max:integer):integer;
begin
     case ch of
          #72 : begin
                     dec(k);
                     if k<0 then k:=max-1;
                end;
          #80 : begin
                     inc(k);
                     if k>max-1 then k:=0;
                end;
     end;
     bouge:=k;
end;

     {initialisation : cette procedure permet d'initialiser le programme cad effacer l'ecran , ...
      il verifie si c'est la premiere fois que l'on a execute le programme si c'est vrai il cree tous les fichiers dont
      le programme a besoin et ensuite demande le nom de l'hotel, le nombre de niveau et le nombre de chambres par niveau
      et ensuite demander les tarifs des chambres et des services annexes et enfin de demander la classe de chaque chambre}

procedure init;
var erreur,i,j,k:integer;
    nb1,nb2:string[5];
    tabchambre:array[1..500] of tchambre;
    dat:tdate;
begin
     today(dat);
     textbackground(white);
     textcolor(yellow);
     clrscr;
     assign(finfo,'c:/hotel/info.dat');
     assign(fcategorie,'c:/hotel/categorie.dat');
     assign(fchambre,'c:/hotel/chambre.dat');
     assign(fser_annexes,'c:/hotel/services_annexes.dat');
     assign(fclient,'c:/hotel/client.dat');
     assign(ffacture,'c:/hotel/facture.dat');
     assign(fconf,'c:/hotel/configuration.dat');
     {$I-}
          mkdir('c:/hotel');
     {$I+}
     erreur:=ioresult;
     {$I-}
          reset(fconf);
     {$I+}
     erreur:=ioresult;
     if erreur<>0 then
     begin
          rewrite(fconf);
          with vconf do
          begin
               couleur_fond:=yellow;
               couleur_select:=0;
               couleur_text_fond:=0;
               couleur_text_select:=white;
               couleur_bas:=white;
               couleur_text_bas:=0;
          end;
          write(fconf,vconf);
     end
     else
         read(fconf,vconf);
         close(fconf);
     {$I-}
          reset(finfo);
     {$I+}
     erreur:=ioresult;
     if erreur=0 then if filesize(finfo)=0 then erreur:=0;
     if erreur<>0 then
     begin
          rewrite(finfo);
          rewrite(fcategorie);
          rewrite(fchambre);
          rewrite(fser_annexes);
          rewrite(fclient);
          rewrite(ffacture);
          efface('I N I T I A L I S A T I O N   :   P R E M I E R E   E X E C U T I O N');
          rect(10,10,30,12);
          gotoxy(17,11);write('HOTEL');
          gotoxy(25,14);write('NOM DE L''HOTEL              :');
          gotoxy(25,16);write('NOMBRE D''ETAGES             :');
          gotoxy(25,18);write('NOMBRE DE CHAMBRE PAR ETAGE :');
          rect(10,20,30,22);
          gotoxy(16,21);write('CATEGORIE');
          gotoxy(25,24);write('  CATEGORIES   ³   TARIF NORMAL   ³   TARIF SPECIAL   ');
          gotoxy(25,25);write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
          gotoxy(25,26);write('  ECONOMIQUE   ³                  ³                   ');
          gotoxy(25,27);write('   STANDING    ³                  ³                   ');
          gotoxy(25,28);write('   AFFAIRE     ³                  ³                   ');

          rect(10,30,30,32);
          gotoxy(12,31);write('SERVICES ANNEXES');
          gotoxy(25,34);write('   SERVICES    ³      PRIX        ');
          gotoxy(25,35);write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
          gotoxy(25,36);write(' PTI DEJEUNER  ³                  ');
          gotoxy(25,37);write('  TELEPHONE    ³                  ');
          gotoxy(25,38);write('     BAR       ³                  ');

          textcolor(blue);

          gotoxy(55,14);read(vinfo.nom);
          gotoxy(55,16);read(vinfo.nbre_niv);
          gotoxy(55,18);read(vinfo.nbre_chambre);
          vinfo.date_debut:=dat;
          write(finfo,vinfo);

          vcategorie.classe:='E';
          gotoxy(44,26);read(vcategorie.tarif_normal);
          gotoxy(64,26);read(vcategorie.tarif_special);
          write(fcategorie,vcategorie);
          vcategorie.classe:='S';
          gotoxy(44,27);read(vcategorie.tarif_normal);
          gotoxy(64,27);read(vcategorie.tarif_special);
          write(fcategorie,vcategorie);
          vcategorie.classe:='A';
          gotoxy(44,28);read(vcategorie.tarif_normal);
          gotoxy(64,28);read(vcategorie.tarif_special);
          write(fcategorie,vcategorie);

          vser_annexes.nom:='PTI DEJEUNER';
          gotoxy(45,36);read(vser_annexes.tarif);
          write(fser_annexes,vser_annexes);
          vser_annexes.nom:='TELEPHONE';
          gotoxy(45,37);read(vser_annexes.tarif);
          write(fser_annexes,vser_annexes);
          vser_annexes.nom:='BAR';
          gotoxy(45,38);read(vser_annexes.tarif);
          write(fser_annexes,vser_annexes);

          close(fcategorie);
          close(fser_annexes);
          textcolor(black);

          k:=0;
          for i:=1 to vinfo.nbre_niv do
          begin
               efface('I N I T I A L I S A T I O N   :   P R E M I E R E   E X E C U T I O N');
               gotoxy(35,8);write('NIVEAU : ',i-1:2);
               gotoxy(21,10);write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
               gotoxy(2,40); write('[E] ECONOMIQUE, [S] STANDIGN,  [A] AFFAIRE');
               for j:=1 to vinfo.nbre_chambre do
               begin
                    str(i-1:2,nb1);
                    if nb1[1]=' ' then nb1[1]:='0';
                    str(j:3,nb2);
                    if nb2[1]=' ' then nb2[1]:='0';
                    if nb2[2]=' ' then nb2[2]:='0';
                    nb1:=nb1+nb2;
                    tabchambre[vinfo.nbre_chambre*(i-1)+j].num:=nb1;
                    tabchambre[vinfo.nbre_chambre*(i-1)+j].etat:='L';
                    gotoxy(20*((j-1) mod 4) + 2,2*(j-1) div 4 + 12);
                    write('CHAMBRE ',nb1,' : ');
               end;
               textcolor(red);
               for j:=1 to vinfo.nbre_chambre do
               begin
                    gotoxy(20*((j-1) mod 4) + 18,2*(j-1) div 4 + 12);
                    repeat
                          ch:=upcase(readkey);
                    until ch in ['S','A','E'];
                    write(ch);
                    tabchambre[vinfo.nbre_chambre*(i-1)+j].classe:=ch;
                    inc(k);
               end;
               textcolor(black);
          end;
          for i:=1 to k do write(fchambre,tabchambre[i]);
     end
     else
         close(finfo);
     generation;
end;

     {la procedure selection permet de colorer un element selectionne du menu}

procedure selection(x,y,max,i,option:integer;var table:ttableau);
begin
     if option=1 then
     begin
          textbackground(vconf.couleur_select);
          textcolor(vconf.couleur_text_select);
     end
     else
     begin
          textbackground(vconf.couleur_fond);
          textcolor(vconf.couleur_text_fond);
     end;
     gotoxy(x,y+3*i);
     write(table[i+1]);
     gotoxy(x,y+1+3*i);
     write(table[max]);
     gotoxy(x,y-1+3*i);
     write(table[max]);
     gotoxy(80,50);
end;

     {procedure information, il donne ttes les informations sur l'hotel}

procedure pinfo;
var i : integer;
    tabinfo : ttableau;

    procedure information;
    var j:integer;
    begin
         rect(2,12,79,40);
         reset(finfo);
         read(finfo,vinfo);
         close(finfo);
         gotoxy(15,16);write('NOM DE L''HOTEL : ',vinfo.nom);
         gotoxy(15,18);write('NOMBRE DE NIVEAU : ',vinfo.nbre_niv);
         gotoxy(15,20);write('NOMBRE DE CHAMBRE PAR NIVEAU : ',vinfo.nbre_chambre);
         reset(fcategorie);
         reset(fser_annexes);
         for j:=1 to 3 do
         begin
              read(fcategorie,vcategorie);
              read(fser_annexes,vser_annexes);
              gotoxy(15,22+2*j);write('CLASSE : ',vcategorie.classe,'; TARIF NORMAL : ',vcategorie.tarif_normal:0:2,
              '; TARIF SPECIAL : ',vcategorie.tarif_special:0:2);
              gotoxy(15,30+2*j);write(vser_annexes.nom,' : ',vser_annexes.tarif:0:2);
         end;
         gotoxy(2,44); write('[E] ECONOMIQUE, [S] STANDIGN,  [A] AFFAIRE');
         close(fcategorie);
         close(fser_annexes);
         repeat
               ch:=readkey;
         until ch=#27;
    end;

    procedure modification;
    begin
          efface('M O D I F I C A T I O N   D E S   P R I X');
          reset(fcategorie);
          reset(fser_annexes);
          rect(10,20,30,22);
          gotoxy(16,21);write('CATEGORIE');
          gotoxy(25,24);write('  CATEGORIES   ³   TARIF NORMAL   ³   TARIF SPECIAL   ');
          gotoxy(25,25);write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
          gotoxy(25,26);write('  ECONOMIQUE   ³                  ³                   ');
          gotoxy(25,27);write('   STANDING    ³                  ³                   ');
          gotoxy(25,28);write('   AFFAIRE     ³                  ³                   ');

          rect(10,30,30,32);
          gotoxy(12,31);write('SERVICES ANNEXES');
          gotoxy(25,34);write('   SERVICES    ³      PRIX        ');
          gotoxy(25,35);write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
          gotoxy(25,36);write(' PTI DEJEUNER  ³                  ');
          gotoxy(25,37);write('  TELEPHONE    ³                  ');
          gotoxy(25,38);write('     BAR       ³                  ');

          textcolor(blue);

          vcategorie.classe:='E';
          gotoxy(44,26);read(vcategorie.tarif_normal);
          gotoxy(64,26);read(vcategorie.tarif_special);
          write(fcategorie,vcategorie);
          vcategorie.classe:='S';
          gotoxy(44,27);read(vcategorie.tarif_normal);
          gotoxy(64,27);read(vcategorie.tarif_special);
          write(fcategorie,vcategorie);
          vcategorie.classe:='A';
          gotoxy(44,28);read(vcategorie.tarif_normal);
          gotoxy(64,28);read(vcategorie.tarif_special);
          write(fcategorie,vcategorie);

          vser_annexes.nom:='PTI DEJEUNER';
          gotoxy(45,36);read(vser_annexes.tarif);
          write(fser_annexes,vser_annexes);
          vser_annexes.nom:='TELEPHONE';
          gotoxy(45,37);read(vser_annexes.tarif);
          write(fser_annexes,vser_annexes);
          vser_annexes.nom:='BAR';
          gotoxy(45,38);read(vser_annexes.tarif);
          write(fser_annexes,vser_annexes);
          close(fser_annexes);
          close(fcategorie);
    end;

    procedure resets;
    var cmd:string;
    begin
         efface('R E I N I T I A L I S A T I O N');
         rect(5,15,75,35);
         gotoxy(32,10);write('ATTENTION  ! ! !');
         gotoxy(10,20);
         write('VOULEZ VOUS BIEN REINITIALISER LE LOGICIEL DE GESTION D''HOTEL');
         gotoxy(13,25);
         write('VOUS ALLEZ PERDRE TOUTES LES INFORMATIONS ENREGISTREES');
         gotoxy(36,30);
         write('[O] / [N]');
         gotoxy(80,50);
         repeat
               ch:=upcase(readkey);
         until ch in ['O','N'];
         if ch='O' then
         begin
              erase(finfo);
              init;
         end;
    end;

    procedure configuration;
    var tab:array[1..6] of integer;
        i,j:integer;
    begin
         i:=1;
         tab[1]:=vconf.couleur_fond;
         tab[2]:=vconf.couleur_text_fond;
         tab[3]:=vconf.couleur_select;
         tab[4]:=vconf.couleur_text_select;
         tab[5]:=vconf.couleur_bas;
         tab[6]:=vconf.couleur_text_bas;
         repeat
               efface('C O N F I G U R A T I O N   C O U L E U R S');
               gotoxy(18,12+3*i); write(#26);
               gotoxy(20,15); write('COULEUR DE FOND');
               gotoxy(20,18); write('COULEUR TEXTE DE FOND');
               gotoxy(20,21); write('COULEUR DE FOND DE SELECTION');
               gotoxy(20,24); write('COULEUR DU TEXTE SELECTIONNE');
               gotoxy(20,27); write('COULEUR DU FOND BAS');
               gotoxy(20,30); write('COULEUR DU TEXTE BAS');
               gotoxy(18,40);write('[ENTER] POUR VALIDER  ET  [ESC] POUR ANNULER');
               for j:=1 to 6 do
               begin
                    textbackground(tab[j]);
                    gotoxy(55,12+3*j); write('   ');
                    textbackground(vconf.couleur_fond);
                    rect(54,11+3*j,58,13+3*j);
               end;
               textbackground(vconf.couleur_fond);
               gotoxy(80,50);
               ch:=readkey;
               case ch of
                    #80: begin
                              gotoxy(18,12+3*i); write(' ');
                              inc(i);
                              if i=7 then i:=1;
                         end;
                    #72: begin
                              gotoxy(18,12+3*i); write(' ');
                              dec(i);
                              if i=0 then i:=6;
                         end;
                    #75: begin
                              dec(tab[i]);
                              if tab[i]=-1 then tab[i]:=0;
                         end;
                    #77: begin
                              inc(tab[i]);
                              if tab[i]=16 then tab[i]:=15;
                         end;
               end;
               vconf.couleur_fond:=tab[1];
               vconf.couleur_text_fond:=tab[2];
               vconf.couleur_select:=tab[3];
               vconf.couleur_text_select:=tab[4];
               vconf.couleur_bas:=tab[5];
               vconf.couleur_text_bas:=tab[6];
         until ch in [#27,#13];
         reset(fconf);
         if ch=#13 then
            write(fconf,vconf)
         else
             read(fconf,vconf);
         close(fconf);
    end;

begin
  REPEAT
     ch:=#0;
     efface('I N F O R M A T I O N   S U R   L '' H O T E L');
     tabinfo[1]:=' LES INFOS                  ';
     tabinfo[2]:=' MODIFIER LE NOM DE L''HOTEL ';
     tabinfo[3]:=' MODIFIER LES TARIFS        ';
     tabinfo[4]:=' REINITIALISER L''HOTEL      ';
     tabinfo[5]:=' LES COULEURS               ';
     tabinfo[6]:=' RETOUR                     ';
     tabinfo[7]:='                            ';
     for i:=0 to 5 do
     begin
          gotoxy(25,15+3*i);
          write(tabinfo[i+1]);
     end;
     i:=0;
     selection(25,15,7,i,1,tabinfo);
     repeat
           if keypressed then
           begin
                ch:=readkey;
                selection(25,15,7,i,2,tabinfo);
                i:=bouge(i,6);
                selection(25,15,7,i,1,tabinfo);
           end;
     until (ch=#13) or (ch=#27);
     inc(i);
     textcolor(black);
     textbackground(white);
     efface('I N F O R M A T I O N   S U R   L '' H O T E L');
     if (ch<>#27) and (i<>6) then
     begin
          rect(2,2,79,6);
          reset(finfo);
          if filesize(finfo)<>0 then read(finfo,vinfo);
          case i of
               1:information;
               2:begin
                      gotoxy(20,30);write('ENTRER LE NOUVEAU NOM DE L''HOTEL : ');
                      gotoxy(55,30);readln(vinfo.nom);
                      rewrite(finfo);
                      write(finfo,vinfo);
                      close(finfo);
                 end;
               3:modification;
               4:resets;
               5:configuration;
          end;
          ch:=#0;
     end;
  UNTIL (ch=#27) or (i=6);
end;

procedure pchambre;
type tachambre=array[1..1000] of tchambre;
     chambre=^tachambre;
var i,j,min,max,nbre_chambre,compteur:integer;
    tabchambre:ttableau;
    chambre1,chambre2:chambre;

    procedure liste(etat:char);
    var i:integer;
    begin
         new(chambre2);
         compteur:=0;
         for i:=1 to nbre_chambre do
         begin
              if chambre1^[i].etat=etat then
              begin
                   inc(compteur);
                   chambre2^[compteur]:=chambre1^[i];
              end;
              if etat='T' then
              begin
                   chambre2^[i]:=chambre1^[i];
                   compteur:=nbre_chambre;
              end;
         end;
         min:=1;
         rect(20,10,60,12);
         gotoxy(21,11);write('      CHAMBRE    CLASSE      ETAT');
         rect(20,13,60,44);
         gotoxy(26,8);write('(',compteur:2,'/',nbre_chambre,')');
         if compteur<30 then max:=compteur else max:=30;
         repeat
               j:=0;
               for i:=1 to 30 do
               begin
                    gotoxy(21,13+i);
                    write('                                      ');
               end;
               for i:=min to max do
               begin
                    inc(j);
                    gotoxy(23,13+j);write('CHAMBRE');
                    gotoxy(31,13+j);write(chambre2^[i].num);
                    gotoxy(38,13+j);
                    case chambre2^[i].classe of
                         'E':write('economique');
                         'S':write('standing');
                         'A':write('affaire');
                    end;
                    gotoxy(50,13+j);
                    case chambre2^[i].etat of
                         'L':write('libre');
                         'O':write('occupee');
                         'R':write('reservee');
                    end;
                    gotoxy(80,50);
               end;
               ch:=readkey;
               case ch of
                    #72:begin
                             if min>1 then
                             begin
                                  dec(min);
                                  dec(max);
                             end;
                        end;
                    #80:begin
                             if max<compteur then
                             begin
                                  inc(min);
                                  inc(max);
                             end;
                        end;
               end;
         until ch=#27;
         dispose(chambre2);
    end;

    procedure class(etat:char);
    var i:integer;
    begin
         new(chambre2);
         compteur:=0;
         for i:=1 to nbre_chambre do
         begin
              if chambre1^[i].classe=etat then
              begin
                   inc(compteur);
                   chambre2^[compteur]:=chambre1^[i];
              end;
         end;
         min:=1;
         rect(20,10,60,12);
         gotoxy(21,11);write('      CHAMBRE    CLASSE      ETAT');
         rect(20,13,60,44);
         gotoxy(21,8);write('(',compteur:2,'/',nbre_chambre,')');
         if compteur<30 then max:=compteur else max:=30;
         repeat
               j:=0;
               for i:=1 to 30 do
               begin
                    gotoxy(21,13+i);
                    write('                                      ');
               end;
               for i:=min to max do
               begin
                    inc(j);
                    gotoxy(23,13+j);write('CHAMBRE');
                    gotoxy(31,13+j);write(chambre2^[i].num);
                    gotoxy(38,13+j);
                    case chambre2^[i].classe of
                         'E':write('economique');
                         'S':write('standing');
                         'A':write('affaire');
                    end;
                    gotoxy(50,13+j);
                    case chambre2^[i].etat of
                         'L':write('libre');
                         'O':write('occupee');
                         'R':write('reservee');
                    end;
                    gotoxy(80,50);
               end;
               ch:=readkey;
               case ch of
                    #72:begin
                             if min>1 then
                             begin
                                  dec(min);
                                  dec(max);
                             end;
                        end;
                    #80:begin
                             if max<compteur then
                             begin
                                  inc(min);
                                  inc(max);
                             end;
                        end;
               end;
         until ch=#27;
         dispose(chambre2);
    end;

    procedure modifier;
    var num:string[5];
        i,j,erreur:integer;
        trouve:boolean;
    begin
      repeat
         efface('L E S   C H A M B R E S');
         rect(19,8,61,12);
         gotoxy(21,10);write('MODIFICATION DE LA CLASSE D''UNE CHAMBRE');
         gotoxy(10,20);write('NUMERO DU CHAMBRE QUE VOUS VOULEZ MODIFIER : ');
         readln(num);
         reset(fchambre);
         trouve:=false;
         i:=-1;
         while not eof(fchambre) and not trouve do
         begin
              inc(i);
              read(fchambre,vchambre);
              trouve:=vchambre.num=num;
         end;
         if trouve then
         begin
              gotoxy(10,23);write('ANCIENNE CLASSE DE LA CHAMBRE ',vchambre.num,' : ',vchambre.classe);
              gotoxy(5,44);write('E = economique ,   S = standing ,   A = affaire');
              gotoxy(10,26);write('ENTRER SA NOUVELLE CLASSE : ');
              repeat
                    ch:=upcase(readkey);
              until ch in ['A','E','S'];
              write(ch);
              vchambre.classe:=ch;
              seek(fchambre,i);write(fchambre,vchambre);
              close(fchambre);
              reset(fchambre);
              nbre_chambre:=filesize(fchambre);
              i:=0;
              while not eof(fchambre) do
              begin
                   inc(i);
                   read(fchambre,vchambre);
                   chambre1^[i]:=vchambre;
              end;
              close(fchambre);
         end
         else
         begin
              gotoxy(17,30);
              textcolor(red + blink);
              write('CETTE CHAMBRE N''EXISTE PAS VERIFIEZ LE NUMERO');
              textcolor(black);
         end;
         gotoxy(2,35);
         write('POUR MODIFIER LA CLASSE D''UNE AUTRE CHAMBRE');
         gotoxy(2,37);
         write('APPUYER [O] SINON SUR UNE AUTRE TOUCHE');
         ch:=upcase(readkey);
      until ch<>'O'
    end;

begin
     new(chambre1);
     reset(fchambre);
     nbre_chambre:=filesize(fchambre);
     i:=0;
     while not eof(fchambre) do
     begin
          inc(i);
          read(fchambre,vchambre);
          chambre1^[i]:=vchambre;
     end;
     close(fchambre);
  Repeat
     ch:=#0;
     efface('L E S   C H A M B R E S');
     tabchambre[1]:=' LISTE DES CHAMBRES               ';
     tabchambre[2]:=' LISTE DES CHAMBRES LIBRES        ';
     tabchambre[3]:=' LISTE DES CHAMBRES OCCUPEES      ';
     tabchambre[4]:=' LISTE DES CHAMBRES RESERVEES     ';
     tabchambre[5]:=' MODIFIER LA CLASSE D''UNE CHAMBRE ';
     tabchambre[6]:=' CHAMBRES : ECONOMIQUES           ';
     tabchambre[7]:=' CHAMBRES : STANDING              ';
     tabchambre[8]:=' CHAMBRES : AFFAIRES              ';
     tabchambre[9]:=' RETOUR                           ';
     tabchambre[10]:='                                  ';
     for i:=0 to 8 do
     begin
          gotoxy(23,15+3*i);
          write(tabchambre[i+1]);
     end;
     i:=0;
     selection(23,15,10,i,1,tabchambre);
     repeat
           if keypressed then
           begin
                ch:=readkey;
                selection(23,15,10,i,2,tabchambre);
                i:=bouge(i,9);
                selection(23,15,10,i,1,tabchambre);
           end;
     until (ch=#13) or (ch=#27);
     inc(i);
     efface('L E S   C H A M B R E S');
     if (ch<>#27) and (i<>9) then
     begin
          rect(2,2,79,6);
          case i of
               1:begin
                      gotoxy(3,8);write('LISTE DES CHAMBRES');
                      liste('T');
                 end;
               2:begin
                      gotoxy(3,8);write('LES CHAMBRES LIBRES');
                      liste('L');
                 end;
               3:begin
                      gotoxy(3,8);write('LES CHAMBRES OCCUPEES');
                      liste('O');
                 end;
               4:begin
                      gotoxy(3,8);write('LES CHAMBRES RESERVEES');
                      liste('R');
                 end;
               5:modifier;
               6:begin
                      gotoxy(3,8);write('CLASSE ECONOMIQUE');
                      class('E');
                 end;
               7:begin
                      gotoxy(3,8);write('CLASSE STANDING');
                      class('S');
                 end;
               8:begin
                      gotoxy(3,8);write('CLASSE AFFAIRE');
                      class('A');
                 end;
          end;
          ch:=#0;
     end;
  UNTIL (ch=#27) or (i=9);
     dispose(chambre1);
end;

procedure pclient;
type tables=array[1..100] of tclient;
     table=^tables;
var tabclient:ttableau;
    date:tdate;
    i,compteur:integer;

    procedure enregistrement(tab:table;indice:integer);
    begin
               gotoxy(50,9);write('PAGE :    /   ');
               gotoxy(62,9);write(compteur);
               gotoxy(57,9);write(i);
               gotoxy(15,12);write('NOM                :');
               gotoxy(15,14);write('PRENOM             :');
               gotoxy(15,16);write('TELEPHONE          :');
               gotoxy(15,18);write('CLASSE             :');
               gotoxy(15,20);write('CHAMBRE            :');
               gotoxy(15,22);write('DATE RESERVATION   :');
               gotoxy(15,24);write('DATE D''ENTREE      : ');
               gotoxy(15,26);write('NUITEE             :');
               gotoxy(15,28);write('DATE SORTIE        :');
               gotoxy(15,30);write('GROUPE SPECIAL     :');
               gotoxy(15,32);write('UTILISE TELEPHONE  :');
               gotoxy(15,34);write('BAR                :');
               gotoxy(15,36);write('PETIT DEJEUNER     :');
               gotoxy(25,38);write('TOTAL :');
               gotoxy(2,44);write('[A] = affaire   [E] = economique   [S] = standing');
               with tab^[i] do
               begin
                    gotoxy(36,12);write(nom);
                    gotoxy(36,14);write(prenom);
                    gotoxy(36,16);write(tel);
                    gotoxy(36,18);
                    case classe of
                         'A':write('affaire');
                         'E':write('economie');
                         'S':write('standing');
                    end;
                    gotoxy(36,20);write(num_chambre);
                    gotoxy(36,22);ecris_date(date_reser);
                    gotoxy(36,24);ecris_date(date_entree);
                    gotoxy(36,26);write(nuite);
                    gotoxy(36,28);ecris_date(date_sortie);
                    gotoxy(36,30);if tarif_spe then write('oui') else write('non');
                    gotoxy(36,32);if phone then write('oui') else write('non');
                    gotoxy(36,34);if bar then write('oui') else write('non');
                    gotoxy(36,36);if pti_dej then write('oui') else write('non');
                    gotoxy(33,38);write(total:0:2);
               end;
    end;

    procedure liste(choix:char);
    var tabl1,tabl2:table;
    begin
         new(tabl1);
         generation;
         reset(fclient);
         compteur:=0;
         today(date);
         reset(fclient);
         efface('L E S   C L I E N T S');
         while not eof(fclient) do
         begin
              read(fclient,vclient);
              case choix of
                   'T':begin
                            gotoxy(13,9);write('LES CLIENTS');
                            inc(compteur);
                            tabl1^[compteur]:=vclient;
                       end;
                   'R':begin
                            gotoxy(9,9);write('LES CLIENTS RESERVES');
                            if sup_date(vclient.date_entree,date) then
                            begin
                                 inc(compteur);
                                 tabl1^[compteur]:=vclient;
                            end;
                       end;
                   'D':begin
                            gotoxy(10,9);write('LES CLIENTS PRESENTS');
                            if not sup_date(vclient.date_entree,date) then
                            begin
                                 inc(compteur);
                                 tabl1^[compteur]:=vclient;
                            end;
                       end;
              end;
         end;
         close(fclient);
         if choix='S' then
         begin
              compteur:=0;
              reset(ffacture);
              while not eof(ffacture) do
              begin
                   read(ffacture,vclient);
                   if not sup_date(vclient.date_sortie,date) and not sup_date(date,vclient.date_sortie) then
                   begin
                        inc(compteur);
                        tabl1^[compteur]:=vclient;
                   end;
              end;
         end;
         i:=1;
         if compteur<>0 then
         repeat
               efface('L E S   C L I E N T S');
               rect(2,8,35,10);
               enregistrement(tabl1,i);
               ch:=readkey;
               case ch of
                    #72:begin
                             dec(i);
                             if i<1 then i:=1;
                        end;
                    #80:begin
                             inc(i);
                             if i>compteur then i:=compteur;
                        end;
               end;
         until ch=#27
         else
         begin
              gotoxy(20,30);write('V I D E');
              repeat
                    ch:=readkey
              until ch=#27;
         end;
         generation;
         dispose(tabl1);
    end;

    procedure suppression;
    var tabl1,tabl2:table;
        a,b:integer;
    begin
         new(tabl1);
         generation;
         reset(fclient);
         compteur:=0;
         today(date);
         while not eof(fclient) do
         begin
              read(fclient,vclient);
              if not sup_date(vclient.date_entree,date) then
              begin
                   inc(compteur);
                   tabl1^[compteur]:=vclient;
              end;
         end;
         close(fclient);
         i:=1;
         if compteur<>0 then
         repeat
               efface('L E S   C L I E N T S');
               rect(2,8,22,10);
               gotoxy(3,9);write('SUPPRESSION CLIENT');
               gotoxy(20,41);write('APPUYER SUR [ENTER] POUR SUPPRIMER');
               enregistrement(tabl1,i);
               ch:=readkey;
               case ch of
                    #72:begin
                             dec(i);
                             if i<1 then i:=1;
                        end;
                    #80:begin
                             inc(i);
                             if i>compteur then i:=compteur;
                        end;
                    #13:begin
                             textcolor(red);
                             gotoxy(20,41);write('       DOIT IL PAYER ? [O/N]      ');
                             repeat
                                   ch:=upcase(readkey);
                             until ch in ['O','N'];
                             new(tabl2);
                             reset(fclient);
                             reset(fchambre);
                             a:=-1;
                             repeat
                                   read(fchambre,vchambre);
                                   inc(a);
                             until eof(fchambre) or (vchambre.num=tabl1^[i].num_chambre);
                             seek(fchambre,a);
                             vchambre.etat:='L';
                             write(fchambre,vchambre);
                             close(fchambre);
                             a:=0;
                             while not eof(fclient) do
                             begin
                                  read(fclient,vclient);
                                  if vclient.num_chambre<>tabl1^[i].num_chambre then
                                  begin
                                       inc(a);
                                       tabl2^[a]:=vclient;
                                  end;
                             end;
                             vclient:=tabl1^[i];
                             reset(ffacture);
                             if ch='O' then
                             begin
                                  today(date);
                                  vclient.nuite:=sous_date(date,vclient.date_entree)+1;
                                  vclient.date_sortie:=date;
                                  seek(ffacture,filesize(ffacture));
                                  write(ffacture,vclient);
                                  close(ffacture);
                             end;
                             i:=1;
                             rewrite(fclient);
                             for b:=1 to a do
                                 write(fclient,tabl2^[b]);
                             close(fclient);
                             dispose(tabl2);
                             generation;
                             ch:=#13;
                    end;
               end;
         until ch in [#27,#13]
         else
         begin
              gotoxy(20,30);write('V I D E');
              repeat
                    ch:=readkey
              until ch=#27;
         end;
         generation;
         dispose(tabl1);
    end;


begin
  repeat
     generation;
     ch:=#0;
     efface('L E S   C L I E N T S');
     tabclient[1]:=' LISTE DES CLIENTS                         ';
     tabclient[2]:=' LISTE DES CLIENTS QUI SORTENT AUJOURD''HUI ';
     tabclient[3]:=' LISTE DES CLIENTS RESERVES                ';
     tabclient[4]:=' LISTE DES CLIENTS QUI SONT DANS L''HOTEL   ';
     tabclient[5]:=' SUPPRESSION CLIENT                        ';
     tabclient[6]:=' RETOUR                                    ';
     tabclient[7]:='                                           ';

     for i:=0 to 5 do
     begin
          gotoxy(19,15+3*i);
          write(tabclient[i+1]);
     end;
     i:=0;
     selection(19,15,7,i,1,tabclient);
     repeat
           if keypressed then
           begin
                ch:=readkey;
                selection(19,15,7,i,2,tabclient);
                i:=bouge(i,6);
                selection(19,15,7,i,1,tabclient);
           end;
     until (ch=#13) or (ch=#27);
     inc(i);
     efface('L E S   C L I E N T S');
     if (ch<>#27) and (i<>6) then
     begin
          rect(2,2,79,6);
          case i of
               1:begin
                      liste('T');
                 end;
               2:begin
                      liste('S');
                 end;
               3:begin
                      liste('R');
                 end;
               4:begin
                      liste('D');
                 end;
               5:suppression;
          end;
          ch:=#0;
     end;
  UNTIL (ch=#27) or (i=6);
end;

procedure preservation;
type tables=array[1..100] of tclient;
     table=^tables;
var compteur,i:integer;
    tabreser:ttableau;
    date:tdate;

    procedure enregistrement(tab:table;indice:integer);
    begin
               gotoxy(50,9);write('PAGE :    /   ');
               gotoxy(62,9);write(compteur);
               gotoxy(57,9);write(i);
               gotoxy(15,12);write('NOM                :');
               gotoxy(15,14);write('PRENOM             :');
               gotoxy(15,16);write('TELEPHONE          :');
               gotoxy(15,18);write('CLASSE             :');
               gotoxy(15,20);write('CHAMBRE            :');
               gotoxy(15,22);write('DATE RESERVATION   :');
               gotoxy(15,24);write('DATE D''ENTREE      :');
               gotoxy(15,26);write('NUITEE             :');
               gotoxy(15,28);write('DATE SORTIE        :');
               gotoxy(15,30);write('GROUPE SPECIAL     :');
               gotoxy(15,32);write('UTILISE TELEPHONE  :');
               gotoxy(15,34);write('BAR                :');
               gotoxy(15,36);write('PETIT DEJEUNER     :');
               gotoxy(25,38);write('TOTAL :');
               gotoxy(2,44);write('[A] = affaire   [E] = economique   [S] = standing');
               with tab^[i] do
               begin
                    gotoxy(36,12);write(nom);
                    gotoxy(36,14);write(prenom);
                    gotoxy(36,16);write(tel);
                    gotoxy(36,18);
                    case classe of
                         'A':write('affaire');
                         'E':write('economie');
                         'S':write('standing');
                    end;
                    gotoxy(36,20);write(num_chambre);
                    gotoxy(36,22);ecris_date(date_reser);
                    gotoxy(36,24);ecris_date(date_entree);
                    gotoxy(36,26);write(nuite);
                    gotoxy(36,28);ecris_date(date_sortie);
                    gotoxy(36,30);if tarif_spe then write('oui') else write('non');
                    gotoxy(36,32);if phone then write('oui') else write('non');
                    gotoxy(36,34);if bar then write('oui') else write('non');
                    gotoxy(36,36);if pti_dej then write('oui') else write('non');
                    gotoxy(33,38);write(total:0:2);
               end;
    end;


    procedure liste;
    var tabl1:table;
    begin
         new(tabl1);
         generation;
         reset(fclient);
         compteur:=0;
         today(date);
         while not eof(fclient) do
         begin
              read(fclient,vclient);
              if sup_date(vclient.date_entree,date) then
              begin
                   inc(compteur);
                   tabl1^[compteur]:=vclient;
              end;
         end;
         close(fclient);
         i:=1;
         if compteur<>0 then
         repeat
               efface('L E S   R E S E R V A T I O N S');
               rect(2,8,19,10);
               gotoxy(3,9);write('LES RESERVATIONS');
               enregistrement(tabl1,i);
               ch:=readkey;
               case ch of
                    #72:begin
                             dec(i);
                             if i<1 then i:=1;
                        end;
                    #80:begin
                             inc(i);
                             if i>compteur then i:=compteur;
                        end;
               end;
         until ch=#27
         else
         begin
              gotoxy(20,30);write('V I D E');
              repeat
                    ch:=readkey
              until ch=#27;
         end;
         generation;
         dispose(tabl1);
    end;

    procedure annuler;
    var tabl1,tabl2:table;
        a,b:integer;
    begin
         new(tabl1);
         generation;
         reset(fclient);
         compteur:=0;
         today(date);
         while not eof(fclient) do
         begin
              read(fclient,vclient);
              if sup_date(vclient.date_entree,date) then
              begin
                   inc(compteur);
                   tabl1^[compteur]:=vclient;
              end;
         end;
         close(fclient);
         i:=1;
         if compteur<>0 then
         repeat
               efface('L E S   R E S E R V A T I O N S');
               rect(2,8,22,10);
               gotoxy(3,9);write('ANNULER RESERVATION');
               gotoxy(20,41);write('APPUYER SUR [ENTRER] POUR SUPPRIMER');
               enregistrement(tabl1,i);
               ch:=readkey;
               case ch of
                    #72:begin
                             dec(i);
                             if i<1 then i:=1;
                        end;
                    #80:begin
                             inc(i);
                             if i>compteur then i:=compteur;
                        end;
                    #13:begin
                             new(tabl2);
                             reset(fclient);
                             reset(fchambre);
                             a:=-1;
                             repeat
                                   read(fchambre,vchambre);
                                   inc(a);
                             until eof(fchambre) or (vchambre.num=tabl1^[i].num_chambre);
                             seek(fchambre,a);
                             vchambre.etat:='L';
                             write(fchambre,vchambre);
                             close(fchambre);
                             a:=0;
                             while not eof(fclient) do
                             begin
                                  read(fclient,vclient);
                                  if vclient.num_chambre<>tabl1^[i].num_chambre then
                                  begin
                                       inc(a);
                                       tabl2^[a]:=vclient;
                                  end;
                             end;
                             i:=1;
                             rewrite(fclient);
                             for b:=1 to a do
                                 write(fclient,tabl2^[b]);
                             close(fclient);
                             dispose(tabl2);
                             generation;
                    end;
               end;
         until ch in [#27,#13]
         else
         begin
              gotoxy(20,30);write('V I D E');
              repeat
                    ch:=readkey
              until ch=#27;
         end;
         generation;
         dispose(tabl1);
    end;

    procedure ajouter;
    var a,n:integer;
        tab:array[1..200] of tchambre;
        today:tdate;
        an,mo,jo,j:word;
    begin
         generation;
         rect(2,8,10,10);gotoxy(4,9);write('ajout');
         gotoxy(15,12);write('NOM                :');
         gotoxy(15,14);write('PRENOM             :');
         gotoxy(15,16);write('TELEPHONE          :');
         gotoxy(15,18);write('CLASSE             :');
         gotoxy(15,20);write('CHAMBRE  [',#24,']/[',#25,']   :');
         gotoxy(15,22);write('DATE D''ENTREE      : jour :      mois :      annee :');
         gotoxy(15,24);write('NUITEE             :');
         gotoxy(15,26);write('DATE SORTIE        :');
         gotoxy(20,29);write('REPONDEZ PAR [O] OU [N]');
         gotoxy(15,32);write('GROUPE SPECIAL ?   :');
         gotoxy(15,34);write('UTILISE TELEPHONE  :');
         gotoxy(15,36);write('BAR                :');
         gotoxy(15,38);write('PETIT DEJEUNER     :');
         gotoxy(25,40);write('TOTAL :');
         gotoxy(2,44);write('[A] = affaire   [E] = economique   [S] = standing   [O] = oui   [N] = non');
         gotoxy(36,12);readln(vclient.nom);
         gotoxy(36,14);readln(vclient.prenom);
         repeat
               gotoxy(36,16);readln(vclient.tel);
               if not valide_phone(vclient.tel) then
               begin
                    gotoxy(36,16);write('                      ');
                    textcolor(blue+blink);
                    gotoxy(2,42);write('nø de telephone invalide, les chiffres, ., - l''espace seulement sont autorises');
                    textcolor(black);
               end;
         until valide_phone(vclient.tel);
         gotoxy(2,42);write('                                                                                ');
         gotoxy(36,18);
         repeat
               ch:=upcase(readkey);
         until ch in ['A','E','S'];
         write(ch);
         vclient.classe:=ch;
         gotoxy(36,20);
         reset(fchambre);
         n:=0;
         while not eof(fchambre) do
         begin
              read(fchambre,vchambre);
              if (vchambre.classe=ch) and (vchambre.etat='L') then
              begin
                   inc(n);
                   tab[n]:=vchambre;
              end;
         end;
         close(fchambre);
         a:=1;
         write(tab[1].num);
         repeat
               ch:=readkey;
               case ch of
                    #72:begin
                             dec(a);
                             if a=0 then a:=1;
                        end;
                    #80:begin
                             inc(a);
                             if a=n+1 then a:=n;
                        end;
               end;
               gotoxy(36,20);write('       ');
               gotoxy(36,20);write(tab[a].num);
         until ch=#13;
         vclient.num_chambre:=tab[a].num;
         getdate(an,mo,jo,j);
         today.annee:=an;
         today.mois:=mo;
         today.jour:=jo;
         repeat
               gotoxy(43,22);write('    ');
               gotoxy(55,22);write('    ');
               gotoxy(68,22);write('    ');
               gotoxy(43,22);readln(vclient.date_entree.jour);
               gotoxy(55,22);readln(vclient.date_entree.mois);
               gotoxy(68,22);readln(vclient.date_entree.annee);
               if not valide_date(vclient.date_entree) or sup_date(today,vclient.date_entree) then
               begin
                    textcolor(red+blink);
                    gotoxy(2,42);write('verifier que la date est valide et qu''il est superieur la date d''aujourd''hui');
                    textcolor(black);
               end;
         until valide_date(vclient.date_entree) and not sup_date(today,vclient.date_entree);
         gotoxy(2,42);write('                                                                                 ');
         gotoxy(36,24);readln(vclient.nuite);
         date_plus(vclient.date_entree,vclient.nuite,vclient.date_sortie);
         gotoxy(36,26);write(vclient.date_sortie.jour,'-',vclient.date_sortie.mois,'-',vclient.date_sortie.annee);
         gotoxy(36,32);
         repeat
               ch:=upcase(readkey);
         until ch in ['O','N'];
         write(ch);
         if ch='O' then vclient.tarif_spe:=true else vclient.tarif_spe:=false;
         gotoxy(36,34);
         repeat
               ch:=upcase(readkey);
         until ch in ['O','N'];
         write(ch);
         if ch='O' then vclient.phone:=true else vclient.phone:=false;
         gotoxy(36,36);
         repeat
               ch:=upcase(readkey);
         until ch in ['O','N'];
         write(ch);
         if ch='O' then vclient.bar:=true else vclient.bar:=false;
         gotoxy(36,38);
         repeat
               ch:=upcase(readkey);
         until ch in ['O','N'];
         write(ch);
         if ch='O' then vclient.pti_dej:=true else vclient.pti_dej:=false;
         vclient.total:=0;
         reset(fcategorie);
         while not eof(fcategorie) and (vcategorie.classe<>vclient.classe) do
              read(fcategorie,vcategorie);
         with vclient do
         begin
              if tarif_spe then
              begin
                   total:=nuite*vcategorie.tarif_special;
                   tarif_chambre:=vcategorie.tarif_special;
              end
              else
              begin
                   total:=nuite*vcategorie.tarif_normal;
                   tarif_chambre:=vcategorie.tarif_normal;
              end;
              reset(fser_annexes);
              while not eof(fser_annexes) and (vser_annexes.nom<>'TELEPHONE') do
                    read(fser_annexes,vser_annexes);
              close(fser_annexes);
              if phone then
              begin
                   total:=total+nuite*vser_annexes.tarif;
                   tarif_phone:=vser_annexes.tarif;
              end;
              reset(fser_annexes);
              while not eof(fser_annexes) and (vser_annexes.nom<>'PTI DEJEUNER') do
                    read(fser_annexes,vser_annexes);
              close(fser_annexes);
              if pti_dej then
              begin
                   total:=total+nuite*vser_annexes.tarif;
                   tarif_pti_dej:=vser_annexes.tarif;
              end;
              reset(fser_annexes);
              while not eof(fser_annexes) and (vser_annexes.nom<>'BAR') do
                    read(fser_annexes,vser_annexes);
              close(fser_annexes);
              if bar then
              begin
                   total:=total+nuite*vser_annexes.tarif;
                   tarif_bar:=vser_annexes.tarif;
              end;
              gotoxy(33,40);
              textcolor(blue+blink);
              write(total:0:2);
              textcolor(black);
         end;
         reset(fclient);
         seek(fclient,filesize(fclient));
         vclient.date_reser:=today;
         write(fclient,vclient);
         close(fclient);
         reset(fchambre);
         a:=-1;
         while not eof(fchambre) and (vclient.num_chambre<>vchambre.num) do
         begin
               read(fchambre,vchambre);
               inc(a);
         end;
         seek(fchambre,a);
         vchambre.etat:='R';
         write(fchambre,vchambre);
         close(fchambre);
         generation;
         readln
    end;

begin
     generation;
  Repeat
     ch:=#0;
     efface('L E S   R E S E R V A T I O N S');
     tabreser[1]:=' LISTE DES RESERVATIONS    ';
     tabreser[2]:=' ANNULER UNE RESERVATION   ';
     tabreser[3]:=' AJOUTER UNE RESERVATION   ';
     tabreser[4]:=' RETOUR                    ';
     tabreser[5]:='                           ';
     for i:=0 to 3 do
     begin
          gotoxy(27,15+3*i);
          write(tabreser[i+1]);
     end;
     i:=0;
     selection(27,15,5,i,1,tabreser);
     repeat
           if keypressed then
           begin
                ch:=readkey;
                selection(27,15,5,i,2,tabreser);
                i:=bouge(i,4);
                selection(27,15,5,i,1,tabreser);
           end;
     until (ch=#13) or (ch=#27);
     inc(i);
     efface('L E S   R E S E R V A T I O N S');
     if (ch<>#27) and (i<>4) then
     begin
          case i of
               1:liste;
               2:annuler;
               3:ajouter;
          end;
          ch:=#0;
     end;
  UNTIL (ch=#27) or (i=4);
end;

procedure pfacture;
type tables=array[1..100] of tclient;
     table=^tables;
var i,compteur:integer;
    tabfact:ttableau;
    tabl1:table;

    procedure enregistrement(tab:table;indice:integer);
    begin
         gotoxy(50,40);write('PAGE :    /   ');
         gotoxy(62,40);write(compteur);
         gotoxy(57,40);write(i);
         gotoxy(1,12);write('DATE RESER. :');
         gotoxy(27,12);write('DATE D''ENTREE :');
         gotoxy(56,12);write('DATE SORTIE :');
         gotoxy(15,14);write('NOM :');
         gotoxy(40,14);write('PRENOM :');
         gotoxy(15,16);write('TELEPHONE :');
         gotoxy(15,18);write('CLASSE :');
         gotoxy(40,18);write('CHAMBRE :');
         gotoxy(60,18);write('NUITE :');
         gotoxy(40,16);write('GROUPE SPECIAL :');
         gotoxy(15,20);write('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿');
         gotoxy(15,21);write('³       DESIGNATIONS      ³   TARIF   ³   TOTAL   ³');
         gotoxy(15,22);write('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄ´');
         gotoxy(15,23);write('³                         ³           ³           ³');
         gotoxy(15,24);write('³ CHAMBRE                 ³           ³           ³');
         gotoxy(15,25);write('³                         ³           ³           ³');
         gotoxy(15,26);write('³ TELEPHONE               ³           ³           ³');
         gotoxy(15,27);write('³                         ³           ³           ³');
         gotoxy(15,28);write('³ BAR                     ³           ³           ³');
         gotoxy(15,29);write('³                         ³           ³           ³');
         gotoxy(15,30);write('³ PETIT DEJEUNER          ³           ³           ³');
         gotoxy(15,31);write('³                         ³           ³           ³');
         gotoxy(15,32);write('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄ´');
         gotoxy(15,33);write('³                                     ³           ³');
         gotoxy(15,34);write('³             T O T A L               ³           ³');
         gotoxy(15,35);write('³                                     ³           ³');
         gotoxy(15,36);write('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÙ');
         with tab^[i] do
         begin
              gotoxy(21,14);write(nom);
              gotoxy(49,14);write(prenom);
              gotoxy(27,16);write(tel);
              gotoxy(24,18);
              case classe of
                   'A':write('affaire');
                   'E':write('economie');
                   'S':write('standing');
              end;
              gotoxy(50,18);write(num_chambre);
              gotoxy(14,12);ecris_date(date_reser);
              gotoxy(42,12);ecris_date(date_entree);
              gotoxy(68,18);write(nuite);
              gotoxy(69,12);ecris_date(date_sortie);
              gotoxy(43,24);write(tarif_chambre:9:0);
              gotoxy(55,24);write(tarif_chambre*nuite:9:0);
              gotoxy(57,16);if tarif_spe then write('oui') else write('non');
              if phone then
              begin
                   gotoxy(43,26);write(tarif_phone:9:0);
                   gotoxy(55,26);write(tarif_phone*nuite:9:0);
              end;
              if bar then
              begin
                   gotoxy(43,28);write(tarif_bar:9:0);
                   gotoxy(55,28);write(tarif_bar*nuite:9:0);
              end;
              if pti_dej then
              begin
                   gotoxy(43,30);write(tarif_pti_dej:9:0);
                   gotoxy(55,30);write(tarif_pti_dej*nuite:9:0);
              end;
              gotoxy(55,34);write(total:9:0);
         end;
    end;

    procedure liste(choix:char);
    var date:tdate;
    begin
         today(date);
         efface('L E S   F A C T U R E S');
         reset(ffacture);
         compteur:=0;
         while not eof(ffacture) do
         begin
              read(ffacture,vclient);
              case choix of
                   'F':begin
                            inc(compteur);
                            tabl1^[compteur]:=vclient;
                       end;
                   'A':begin
                            if not sup_date(vclient.date_sortie,date) and not sup_date(date,vclient.date_sortie) then
                            begin
                                 inc(compteur);
                                 tabl1^[compteur]:=vclient;
                            end;
                       end;
              end;
         end;
         close(ffacture);
         i:=1;
         if compteur<>0 then
         repeat
               efface('L E S   F A C T U R E S');
               enregistrement(tabl1,i);
               ch:=readkey;
               case ch of
                    #72:begin
                             dec(i);
                             if i<1 then i:=1;
                        end;
                    #80:begin
                             inc(i);
                             if i>compteur then i:=compteur;
                        end;
               end;
         until ch=#27
         else
         begin
              gotoxy(20,30);write('V I D E');
              repeat
                    ch:=readkey
              until ch=#27;
         end;
         generation;
    end;

begin
     new(tabl1);
     generation;
  repeat
     ch:=#0;
     efface('L E S   F A C T U R E S');
     tabfact[1]:=' LISTE DES FACTURES         ';
     tabfact[2]:=' LES FACTURES D''AUJOURD''HUI ';
     tabfact[3]:=' RETOUR                     ';
     tabfact[4]:='                            ';
     for i:=0 to 2 do
     begin
          gotoxy(26,15+3*i);
          write(tabfact[i+1]);
     end;
     i:=0;
     selection(26,15,4,i,1,tabfact);
     repeat
           if keypressed then
           begin
                ch:=readkey;
                selection(26,15,4,i,2,tabfact);
                i:=bouge(i,3);
                selection(26,15,4,i,1,tabfact);
           end;
     until (ch=#13) or (ch=#27);
     inc(i);
     efface('L E S   F A C T U R E S');
     if (ch<>#27) and (i<>3) then
     begin
          case i of
               1:liste('F');
               2:liste('A');
          end;
          ch:=#0;
     end;
  UNTIL (ch=#27) or (i=3);
  dispose(tabl1);
end;

procedure pstatistique;
type tstat = record
                   nclasse_e,nclasse_s,nclasse_a:integer;
                   mclasse_e,mclasse_s,mclasse_a:real;
                   nbar,ntel,npti_dej:integer;
                   mbar,mtel,mpti_dej,mchambre:real;
             end;
     tablestat = array[1..12] of tstat;
var i,min,max:integer;
    tabstat:ttableau;
    contenu : array[1..10,1..15] of integer;
    couts : array[1..8,1..15] of real;

    date:tdate;

    procedure trace_tableau_generation(choix:string;an:integer);
    var a,i,j:integer;
    begin
         today(date);
         if choix='MP' then
         begin
              gotoxy(4,09); write('             ÚÄÄÄÄÂÄÄÄÄÂÄÄÄÄÂÄÄÄÄÂÄÄÄÄÂÄÄÄÄÂÄÄÄÄÂÄÄÄÄÂÄÄÄÄÂÄÄÄÄÂÄÄÄÄÂÄÄÄÄ¿');
              gotoxy(4,10); write('             ³ 01 ³ 02 ³ 03 ³ 04 ³ 05 ³ 06 ³ 07 ³ 08 ³ 09 ³ 10 ³ 11 ³ 12 ³');
              gotoxy(4,11); write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄ´');
              for a:=1 to 10 do
              begin
                   gotoxy(4,12+2*(a-1)); write('             ³    ³    ³    ³    ³    ³    ³    ³    ³    ³    ³    ³    ³');
                   gotoxy(4,13+2*(a-1)); write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄ´');
              end;
              gotoxy(4,31); write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÙ');
              gotoxy(4,12); write('ENTREES');
              gotoxy(4,14); write('SORTIES');
              gotoxy(4,16); write('RESERVATIONS');
              gotoxy(4,18); write('ECONOMIQUE');
              gotoxy(4,20); write('STANDING');
              gotoxy(4,22); write('AFFAIRE');
              gotoxy(4,24); write('BAR');
              gotoxy(4,26); write('PTI DEJEUNER');
              gotoxy(4,28); write('TELEPHONE');
              gotoxy(4,30); write('TARIF SPE.');
         end;
         if choix='MA' then
         begin
              gotoxy(2,09); write('    ÚÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄ¿');
              gotoxy(2,10); write('mois³  ECO   ³  STA   ³  AFF   ³  G.S   ³  P.D   ³  TEL   ³  BAR   ³  TOTAL  ³');
              gotoxy(2,11); write('ÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄ´');
              for a:=1 to 12 do
              begin
                   gotoxy(2,12+2*(a-1));
                            write('    ³        ³        ³        ³        ³        ³        ³        ³         ³');
                   gotoxy(3,12+2*(a-1)); write(a:2);
                   gotoxy(2,13+2*(a-1));
                            write('ÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄ´');
              end;
              gotoxy(2,35); write('ÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÙ');
         end;

         if choix='SA' then
         begin
              gotoxy(2,09); write('             ÚÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄ¿');
              gotoxy(2,10); write('             ³ SEM 01 ³ SEM 02 ³ ANNEE  ³');
              gotoxy(2,11); write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄ´');
              for a:=1 to 10 do
              begin
                   gotoxy(2,12+2*(a-1));
                            write('             ³        ³        ³        ³');
                   gotoxy(2,13+2*(a-1));
                            write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄ´');
              end;
              gotoxy(2,31); write('ÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÙ');
              gotoxy(2,12); write('ENTREES');
              gotoxy(2,14); write('SORTIES');
              gotoxy(2,16); write('RESERVATIONS');
              gotoxy(2,18); write('ECONOMIQUE');
              gotoxy(2,20); write('STANDING');
              gotoxy(2,22); write('AFFAIRE');
              gotoxy(2,24); write('BAR');
              gotoxy(2,26); write('PTI DEJEUNER');
              gotoxy(2,28); write('TELEPHONE');
              gotoxy(2,30); write('TARIF SPE.');
              gotoxy(47,19); write('     ÚÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄ¿');
              gotoxy(47,20); write('     ³ SEM 01 ³ SEM 02 ³ ANNEE  ³');
              gotoxy(47,21); write('ÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄ´');
              for a:=1 to 8 do
              begin
                   gotoxy(47,22+2*(a-1));
                             write('     ³        ³        ³        ³');
                   gotoxy(47,23+2*(a-1));
                             write('ÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄ´');
              end;
              gotoxy(47,37); write('ÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÙ');
              gotoxy(48,22); write('ECO');
              gotoxy(48,24); write('STA');
              gotoxy(48,26); write('AFF');
              gotoxy(48,28); write('G.S');
              gotoxy(48,30); write('P.D');
              gotoxy(48,32); write('TEL');
              gotoxy(48,34); write('BAR');
              gotoxy(47,36); write('TOTAL');
         end;

         for i:=1 to 10 do
             for j:=1 to 15 do
                 contenu[i,j]:=0;
         for i:=1 to 8 do
             for j:=1 to 15 do
                 couts[i,j]:=0;
         reset(ffacture);
         while not eof(ffacture) do
         begin
              read(ffacture,vfacture);
              with vfacture do
              begin
                   if date_entree.annee=an then
                   begin
                        inc(contenu[1,date_entree.mois]);
                        if classe='E' then inc(contenu[4,date_entree.mois]);
                        if classe='S' then inc(contenu[5,date_entree.mois]);
                        if classe='A' then inc(contenu[6,date_entree.mois]);
                        if bar then inc(contenu[7,date_entree.mois]);
                        if pti_dej then inc(contenu[8,date_entree.mois]);
                        if phone then inc(contenu[9,date_entree.mois]);
                        if tarif_spe then inc(contenu[10,date_entree.mois]);
                   end;
                   if date_sortie.annee=an then
                   begin
                        inc(contenu[2,date_sortie.mois]);
                        if classe='E' then couts[1,date_entree.mois]:=couts[1,date_entree.mois]+nuite*tarif_chambre;
                        if classe='S' then couts[2,date_entree.mois]:=couts[2,date_entree.mois]+nuite*tarif_chambre;
                        if classe='A' then couts[3,date_entree.mois]:=couts[3,date_entree.mois]+nuite*tarif_chambre;
                        if tarif_spe then couts[4,date_entree.mois]:=couts[4,date_entree.mois]+nuite*tarif_chambre;
                        if pti_dej then couts[5,date_entree.mois]:=couts[5,date_entree.mois]+nuite*tarif_pti_dej;
                        if phone then couts[6,date_entree.mois]:=couts[6,date_entree.mois]+nuite*tarif_phone;
                        if bar then couts[7,date_entree.mois]:=couts[7,date_entree.mois]+nuite*tarif_bar;
                   end;
                   if date_reser.annee=an then
                      inc(contenu[3,date_reser.mois]);
              end;
         end;
         for i:=1 to 12 do
             for j:=1 to 7 do
                 if j<>4 then couts[8,i]:=couts[8,i]+couts[j,i];
         close(ffacture);
         reset(fclient);
         while not eof(fclient) do
         begin
              read(fclient,vclient);
              with vclient do
              begin
                   if date_entree.annee=an then
                   begin
                        if not sup_date(vclient.date_entree,date) then
                        begin
                             inc(contenu[1,date_entree.mois]);
                             if classe='E' then inc(contenu[4,date_entree.mois]);
                             if classe='S' then inc(contenu[5,date_entree.mois]);
                             if classe='A' then inc(contenu[6,date_entree.mois]);
                             if bar then inc(contenu[7,date_entree.mois]);
                             if pti_dej then inc(contenu[8,date_entree.mois]);
                             if phone then inc(contenu[9,date_entree.mois]);
                             if tarif_spe then inc(contenu[10,date_entree.mois]);
                        end;
                   end;
                   if date_reser.annee=an then
                      inc(contenu[3,date_reser.mois]);
              end;
         end;
         for i:=1 to 10 do
             for j:=1 to 12 do
             begin
                  contenu[i,15]:=contenu[i,15]+contenu[i,j];
                  if j<7 then contenu[i,13]:=contenu[i,13]+contenu[i,j];
                  if j>6 then contenu[i,14]:=contenu[i,14]+contenu[i,j];
             end;
         for i:=1 to 8 do
             for j:=1 to 12 do
             begin
                  couts[i,15]:=couts[i,15]+couts[i,j];
                  if j<7 then couts[i,13]:=couts[i,13]+couts[i,j];
                  if j>6 then couts[i,14]:=couts[i,14]+couts[i,j];
             end;
         close(fclient);
    end;

    procedure mensuel;
    var i,a,b,an:integer;

        procedure personne;
        var a,b:integer;
        begin
             an:=max;
             repeat
                   efface('S T A T I S T I Q U E   *   M E N S U E L   *   L E S   P E R S O N N E S');
                   trace_tableau_generation('MP',an);
                   gotoxy(25,35); write('FLUX DE PERSONNES DE L''ANNEE ',an);
                   gotoxy(10,44); write('PRECEDENT : [',#27,']     SUIVANT : [',#26,']');
                   textcolor(2);
                   for a:=1 to 10 do
                       for b:=1 to 12 do
                       begin
                            if contenu[a,b]<>0 then
                            begin
                                 gotoxy(19+5*(b-1),12+2*(a-1));
                                 write(contenu[a,b]);
                            end;
                       end;
                   textcolor(black);
                   gotoxy(80,50);
                   ch:=readkey;
                   case ch of
                        #75:begin
                                 dec(an);
                                 if an<min then an:=min
                            end;
                        #77:begin
                                 inc(an);
                                 if an>max then an:=max
                            end;
                   end;
             until ch=#27;
        end;

        procedure argent;
        var a,b:integer;
        begin
             an:=max;
             repeat
                   efface('S T A T I S T I Q U E   *   M E N S U E L   *   A R G E N T');
                   trace_tableau_generation('MA',an);
                   gotoxy(27,40); write('FLUX D''ARGENT DE L''ANNEE ',an);
                   gotoxy(10,44); write('PRECEDENT : [',#27,']     SUIVANT : [',#26,']');
                   textcolor(2);
                   for a:=1 to 8 do
                       for b:=1 to 12 do
                       begin
                            if couts[a,b]<>0 then
                            begin
                                 gotoxy(7+9*(a-1),12+2*(b-1));
                                 write((couts[a,b]):8:0);
                            end;
                       end;
                   textcolor(black);
                   gotoxy(80,50);
                   ch:=readkey;
                   case ch of
                        #75:begin
                                 dec(an);
                                 if an<min then an:=min
                            end;
                        #77:begin
                                 inc(an);
                                 if an>max then an:=max
                            end;
                   end;
             until ch=#27;
        end;

    begin
         repeat
               ch:=#0;
               efface('S T A T I S T I Q U E S   *   M E N S U E L');
               tabstat[1]:=' PERSONNES ';
               tabstat[2]:=' ARGENT    ';
               tabstat[3]:=' RETOUR    ';
               tabstat[4]:='           ';
               for i:=0 to 2 do
               begin
                    gotoxy(33,15+3*i);
                    write(tabstat[i+1]);
               end;
               i:=0;
               selection(33,15,4,i,1,tabstat);
               repeat
                     if keypressed then
                     begin
                          ch:=readkey;
                          selection(33,15,4,i,2,tabstat);
                          i:=bouge(i,3);
                          selection(33,15,4,i,1,tabstat);
                     end;
               until (ch=#13) or (ch=#27);
               inc(i);
               efface('S T A T I S T I Q U E S   *   M E N S U E L');
               if (ch<>#27) and (i<>3) then
               begin
                    case i of
                         1:personne;
                         2:argent;
                    end;
                    ch:=#0;
               end;
         UNTIL (ch=#27) or (i=3);
    end;

    procedure semesannuel;
    var an,a,b:integer;
    begin
             an:=max;
             repeat
                   efface('S T A T I S T I Q U E   *   S E M E S T R I E L   &   A N N U E L');
                   trace_tableau_generation('SA',an);
                   gotoxy(49,40); write('FLUX D''ARGENT DE L''ANNEE ',an);
                   gotoxy(5,35); write('FLUX DE PERSONNES DE L''ANNEE ',an);
                   gotoxy(10,44); write('PRECEDENT : [',#27,']     SUIVANT : [',#26,']');
                   textcolor(2);
                   for a:=1 to 10 do
                       for b:=13 to 15 do
                       begin
                            if contenu[a,b]<>0 then
                            begin
                                 gotoxy(19+9*(b-13),12+2*(a-1));
                                 write(contenu[a,b]:2);
                            end;
                            if a<9 then
                               if couts[a,b]<>0 then
                               begin
                                    gotoxy(53+9*(b-13),22+2*(a-1));
                                    write(couts[a,b]:8:0);
                               end;
                       end;
                   textcolor(black);
                   gotoxy(80,50);
                   ch:=readkey;
                   case ch of
                        #75:begin
                                 dec(an);
                                 if an<min then an:=min
                            end;
                        #77:begin
                                 inc(an);
                                 if an>max then an:=max
                            end;
                   end;
             until ch=#27;
    end;

begin
     reset(finfo);
     read(finfo,vinfo);
     close(finfo);
     min:=vinfo.date_debut.annee;
     today(date);
     max:=date.annee;
     generation;
  repeat
     ch:=#0;
     efface('S T A T I S T I Q U E S');
     tabstat[1]:=' MENSUEL             ';
     tabstat[2]:=' SEMESTRIEL & ANNUEL ';
     tabstat[3]:=' RETOUR              ';
     tabstat[4]:='                     ';
     for i:=0 to 2 do
     begin
          gotoxy(29,15+3*i);
          write(tabstat[i+1]);
     end;
     i:=0;
     selection(29,15,4,i,1,tabstat);
     repeat
           if keypressed then
           begin
                ch:=readkey;
                selection(29,15,4,i,2,tabstat);
                i:=bouge(i,3);
                selection(29,15,4,i,1,tabstat);
           end;
     until (ch=#13) or (ch=#27);
     inc(i);
     efface('S T A T I S T I Q U E S');
     if (ch<>#27) and (i<>3) then
     begin
          case i of
               1:mensuel;
               2:semesannuel;
          end;
          ch:=#0;
     end;
  UNTIL (ch=#27) or (i=3);
end;

procedure aide;
begin
     efface('A I D E');
     rect(10,12,72,35);
     window(12,15,70,38);
     writeln('DANS LES MENUS VOUS POUVEZ SELECTIONNER PAR LES TOUCHES ');
     writeln;
     writeln('HAUT [',#24,'] POUR MONTER ET BAS [',#25,'] POUR DESCENDRE');
     writeln;
     writeln('POUR VALIDER, VOUS APPUYER SUR LA TOUCHE ENTREE [ENTER]');
     writeln;
     writeln('ET POUR RETOURNER VERS LE MENU PRECEDENT VOUS SELECTIONNER');
     writeln;
     writeln('RETOUR OU APPUYER SUR ECHAP [ESC]');
     writeln;
     writeln;
     writeln('LEGENDE :');
     writeln;
     writeln('      E = ECONOMIQUE     S = STANDING    C = CLASSE');
     writeln;
     writeln('DANS LA PARTIE STATISTIQUES, AU LIEU D''ECRIRE LES MOIS,');
     writeln;
     writeln('NOUS AVONS UTILISE LE NUMERO DU MOIS (COMME 3 POUR MARS)');
     repeat
           ch:=readkey;
     until ch=#27;
     window(1,1,80,50);
end;

     {menu principal}

procedure menu;
var i:integer;
    tabmenu:ttableau;
begin
  REPEAT
     generation;
     efface('M E N U   P R I N C I P A L');
     tabmenu[1]:='  GESTION DE L''HOTEL         ';
     tabmenu[2]:='  LES CHAMBRES               ';
     tabmenu[3]:='  LES CLIENTS                ';
     tabmenu[4]:='  LES RESERVATIONS           ';
     tabmenu[5]:='  LES FACTURES               ';
     tabmenu[6]:='  STATISTIQUES               ';
     tabmenu[7]:='  AIDE                       ';
     tabmenu[8]:='  QUITTER                    ';
     tabmenu[9]:='                             ';
     for i:=0 to 7 do
     begin
          gotoxy(25,15+3*i);
          write(tabmenu[i+1]);
     end;
     i:=0;
     selection(25,15,9,i,1,tabmenu);
     repeat
           if keypressed then
           begin
                ch:=readkey;
                selection(25,15,9,i,2,tabmenu);
                i:=bouge(i,8);
                selection(25,15,9,i,1,tabmenu);
           end;
     until (ch=#13) or (ch=#27);
     inc(i);
     if (ch<>#27) and (i<>8) then
     begin
          rect(2,2,79,6);
          case i of
               1:pinfo;
               2:pchambre;
               3:pclient;
               4:preservation;
               5:pfacture;
               6:pstatistique;
               7:aide;
          end;
          ch:=#0;
     end;
  UNTIL (ch=#27) or (i=8);
end;

               {----------   PROGRAMME PRINCIPAL   ----------}

BEGIN
     init;
     menu;
END.