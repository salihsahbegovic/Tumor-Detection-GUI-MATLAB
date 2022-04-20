function varargout = Detekcija_tumora(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Detekcija_tumora_OpeningFcn, ...
                   'gui_OutputFcn',  @Detekcija_tumora_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

%Dio koda koji se pokrece pri svakom pokretanju sistema.
%U ovom dijelu svim podacima dodjeljujemo pocetnu vrijednost 0, te
%sakrivamo tekst koji nam govori je li detektovan tumor ili ne
function Detekcija_tumora_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);
set(handles.text4,'visible','off');
A=0;
string0='Unesite snimak MR skena.';
set(handles.text1,'String',string0);
setappdata(handles.figure1,'SnimakSkena',A);
setappdata(handles.figure1,'FiltriranaSlika',A);
setappdata(handles.figure1,'Tumor',A);
setappdata(handles.figure1,'trazenaKutija',A);
setappdata(handles.figure1,'TumorGranice',A);
setappdata(handles.figure1,'UneseneGraniceTumora',A);

function varargout = Detekcija_tumora_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

%Aktivacijom tastera za unos slike, pokrece se prozor koji zahtjeva da se
%unese slika. Unosom slike pokrece se i ostatak koda. U ostatku ovog dijela
%koda vrši se: filtriranje slike, izdvajanje samog tumora, određivanje
%njegove granicne kutije, određivanje granica i lokacije tumora. Svi
%izracunati podaci se spremaju u memoriju GUI, te se koriste po potrebi
%aktivacijom drugih, odgovarajucih, tastera u GUI.
function pushbutton1_Callback(hObject, eventdata, handles)
%Dio koda koji otvara prozor za unosenje slike.
A=0;
[NazivFajla,Adresa]=uigetfile({'*.jpg';'*.png'},'Izaberi ulaznu sliku');
A=imread(strcat(Adresa,NazivFajla));
%Provjerava da li je snimak unesen.
if A==0 %Ako nije, A je 0 i korisniku je jos uvijek ispisana poruka da unese snimak MR skena
    string0='Unesite snimak MR skena.';
    set(handles.text1,'String',string0);
else %Ako je unesena slika, korisniku se ispisuje da je snimak unesen i 
     %vrsi se detekcija eventualnog tumora, te ostali proracuni.
   string2='Unešen je snimak MR skena.';
   set(handles.text1,'String',string2);
   axes(handles.axes1);
   imshow(A);
   setappdata(handles.figure1,'SnimakSkena',A); %Spremanje u memoriju slike skena
%Filtriranje slike      
F=imdiffusefilt(A); 
C = uint8(F);
C=imresize(C,[256,256]);  
if size(C,3)>1 % Vraca prve tri dimenzije
    C=rgb2gray(C);% Pretvara filtriranu sliku u sliku s nivoima sivog
end
setappdata(handles.figure1,'FiltriranaSlika',C); %Spremanje u memoriju filtrirane slike
F=imbinarize(C,0.7); %Binariziranje slike
%Vrse se morfološke operacije nad slikom

oznaka=bwlabel(F); %Izdvajanje obiljezja - IZDVAJANJE TUMORA (na osnovu gustine tog dijela u usporedbi s ostalim dijelovima mozga)
Podaci=regionprops(logical(F),'Solidity','Area','BoundingBox'); %Izvlacenje podataka(stastike) o navedenim obiljezjima
Gustoca=[Podaci.Solidity];
Povrsina=[Podaci.Area];
PodrucjeVisokeGustine=Gustoca>0.6; %izdvaja povrsine cija je gustina veca od 60% gustine mozga
MaksimalnaPovrsina=max(Povrsina(PodrucjeVisokeGustine));
OznakaTumora=find(Povrsina==MaksimalnaPovrsina);
tumor=ismember(oznaka,OznakaTumora);
if MaksimalnaPovrsina>100 %Prag da bi se neka povrsina smatrala tumorom, ako je maksimalna povrsina veca od praga
                          %Tumor je detektovan i ta se poruka ispisuje
                          %korisniku
   string3='Tumor je detektovan.';
   set(handles.text4,'String',string3);
   set(handles.text4,'visible','on');
   setappdata(handles.figure1,'OznakaTumora',OznakaTumora); %Spremanje u memoriji oznake tumora
   setappdata(handles.figure1,'Tumor',tumor);%Spremanje u memoriji izdvojenog tumora
%Izdvajanje granicne 'kutije' tumora
   Kutija=OznakaTumora;
   kutija = Podaci(Kutija)
   TrazenaKutija=kutija.BoundingBox;
   setappdata(handles.figure1,'trazenaKutija',TrazenaKutija); 
   %Spremanje u memoriji koordinata granicne kutije tumora
%OdREDJIVANJE GRANICA TUMORA
    PopunjenaSlika = imfill(tumor, 'holes');
    StrukturniElement=strel('square',11);
    ErozivnaSlika=imerode(PopunjenaSlika,StrukturniElement);
    tumorGranice=tumor;
    tumorGranice(ErozivnaSlika)=0;
    setappdata(handles.figure1,'TumorGranice',tumorGranice);
%Odredjivanje lokacije tumora
    novo=C;
    granice=tumorGranice;
    rgb = novo(:,:,[1 1 1]);
    crvena = rgb(:,:,1);
    crvena(granice)=255;
    zelena= rgb(:,:,2);
    zelena(granice)=0;
    plava = rgb(:,:,3);
    plava(granice)=0;
    uneseneGraniceTumora(:,:,1) = crvena; 
    uneseneGraniceTumora(:,:,2) = zelena; 
    uneseneGraniceTumora(:,:,3) = plava; 
    setappdata(handles.figure1,'unesenegranicetumora',uneseneGraniceTumora);
    %Spremanje u memoriji unesenih granica tumora
else %U suprotnom, tumor nije detektovan i ta se poruka ispisuje korisniku
   string4='Tumor nije detektovan.';
   set(handles.text4,'String',string4);
   set(handles.text4,'visible','on');
end
end

%Taster za prikaz filtrirane slike
function pushbutton2_Callback(hObject, eventdata, handles)
B=getappdata(handles.figure1,'SnimakSkena');
C=getappdata(handles.figure1,'FiltriranaSlika');
if B==0 %ako snimak MR skena nije unesen, korisnik se obavjestava
    string3='Nije unešen snimak MR skena.';
    set(handles.text1,'String',string3);
else %Ako je snimak Mr skena unesen, prikazuje se filtrirana slika
axes(handles.axes2);
imshow(C);
end

%Izdvajanje samog tumora
function pushbutton3_Callback(hObject, eventdata, handles)
B=getappdata(handles.figure1,'SnimakSkena'); %Sa komandom getappdata pozivaju se potrebni spremljeni podaci
E=getappdata(handles.figure1,'Tumor');
if B==0
    string3='Nije unešen snimak MR skena.';
    set(handles.text1,'String',string3);
else
if isequal(E,0) %Ako je tumor izdvojen (detektovan), ta se poruka ispisuje i tumor prikazuje
   string1='Tumor nije detektovan';
   set(handles.text4,'String',string1);
   set(handles.text4,'visible','on');
else
   axes(handles.axes3);
   imshow(E);
   string0='Tumor je detektovan';
   set(handles.text4,'String',string0);
   set(handles.text4,'visible','on');
end
end


%Izdvajanje tumora u kutiji
function pushbutton4_Callback(hObject, eventdata, handles)
B=getappdata(handles.figure1,'SnimakSkena');
C=getappdata(handles.figure1,'trazenaKutija');
D=getappdata(handles.figure1,'FiltriranaSlika');
if B==0
    string3='Nije unešen snimak MR skena.';
    set(handles.text1,'String',string3);
else
if isequal(C,0)
string1='Tumor nije detektovan.';
set(handles.text4,'String',string1);
set(handles.text4,'visible','on');
else 
string1='Tumor je detektovan.';
set(handles.text4,'String',string1);
set(handles.text4,'visible','on');
axes(handles.axes4);
imshow(D);
hold on;
rectangle('Position',C,'EdgeColor','g');
hold off;
end
end


%Izdvajanje granica tumora
function pushbutton5_Callback(hObject, eventdata, handles)
B=getappdata(handles.figure1,'SnimakSkena');
C=getappdata(handles.figure1,'Tumor');
D=getappdata(handles.figure1,'TumorGranice');
if B==0
    string3='Nije unešen snimak MR skena.';
    set(handles.text1,'String',string3);
else
if isequal(C,0)
string1='Tumor nije detektovan.';
set(handles.text4,'String',string1);
set(handles.text4,'visible','on');
else 
string1='Tumor je detektovan.';
set(handles.text4,'String',string1);
set(handles.text4,'visible','on');
axes(handles.axes5);
imshow(D);
end
end

%Lokacija tumora
function pushbutton6_Callback(hObject, eventdata, handles)
B=getappdata(handles.figure1,'SnimakSkena');
E=getappdata(handles.figure1,'Tumor');
F=getappdata(handles.figure1,'unesenegranicetumora');
if B==0
    string3='Nije unešen snimak MR skena.';
    set(handles.text1,'String',string3);
else
if isequal(E,0)
 string1='Tumor nije detektovan.';
set(handles.text4,'String',string1);
set(handles.text4,'visible','on');
else 
string1='Tumor je detektovan.';
set(handles.text4,'String',string1);
set(handles.text4,'visible','on');
axes(handles.axes6);
imshow(F);
end
end

%Izlaz iz aplikacije
function pushbutton7_Callback(hObject, eventdata, handles)
delete(handles.figure1);

%Restart aplikacije! Ovaj dio koda uklanja slike iz svih prozora,
%Postavlja vrijednost svih podataka na 0, te vraca pocetnu vrijednost
%teksta. Osim toga, sakriva tekst koji nam govori je li tumor detektovan
%ili ne
function pushbutton8_Callback(hObject, eventdata, handles)
set(handles.text4,'visible','off')
cla(handles.axes1);
cla(handles.axes2);
cla(handles.axes3);
cla(handles.axes4);
cla(handles.axes5);
cla(handles.axes6);
string0='Unesite snimak MR skena.';
set(handles.text1,'String',string0);
A=0;
setappdata(handles.figure1,'FiltriranaSlika',A);
setappdata(handles.figure1,'SnimakSkena',A);
setappdata(handles.figure1,'TumorGranice',A);
setappdata(handles.figure1,'Tumor',A);
setappdata(handles.figure1,'trazenaKutija',A);
setappdata(handles.figure1,'UneseneGraniceTumora',A);
