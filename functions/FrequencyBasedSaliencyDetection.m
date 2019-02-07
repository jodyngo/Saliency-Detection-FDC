function [sl_map,salient_im,ft_map]=FrequencyBasedSaliencyDetection(im_in,params)
%DCTbasedSalientDetection ����Ƶ�����������Ŀ�����㷨
%�ԱȲ�ͬ��������ȡ�������˲����µ������Լ����
%ʹ��DCT�任�����ֿ�ѡ��Ƶ��任������������ͼ��
%   sign������
%   log����
%   sigmod������
%   �ײв
%   ���⻯�任
%   SSS
%
%ʹ��3�ֿ�ѡ���˲�������ǰ��ǿ��ͼ��
%   gauss��ͨ�˲���
%   ��˹��ִ�ͨ�˲���
%   
%
%   �������Ϊ������������ͨ������ͼ��
%   @im_in      �����ͼ��
%   @params     ����Ŀ���������������ѡ�õ�Ƶ��������ȡ��������������ͼ���˲�����������
%   �����
%   @sl_map     ����ͼ
%   @salient_im ����ͼ��Ĥ�µ�ԭͼ
%   @ft_map     ����ǿ��ͼ

im_in=im2double(im_in);

% ��ɫ�ռ�ѡ��
if ~isfield( params, 'colorSpace' )
    params.colorSpace=0;
end
im_in_use=colorSpace(im_in,params.colorSpace);

% ��������ǿ��ͼ
if ~isfield( params, 'ftPara' )
    params.ftPara.way='sign';
end
ft_map=featureMap(im_in_use,params.ftPara);

% �������Ļ�����
if ~isfield( params, 'centra' )
    params.centra=0;
end
ft_map=centralization(ft_map,params.centra);

% ���������ֲ�ͼ
if ~isfield( params, 'slPara' )
    params.slPara.kernel='gaussLow';
end
sl_map=salientMap(ft_map,params.slPara);

% �ں�ԭͼ��������������ǿ
[n,m,c]=size(im_in);
salient_im=zeros(n,m,c);
for i=1:c
    salient_im(:,:,i)=im_in(:,:,i).*sl_map;
end
end

%% ��ɫ�ռ�任����
function im_out=colorSpace(im_in,colorSpace)
% ��ͼ�������ɫ�ռ�任��Ĭ��ΪRGB
%   @im_in      ����ͼ��
%   @colorSpace Ŀ����ɫ�ռ�
%   @im_out     ���ͼ��

if ~exist( 'colorSpace', 'var' )
    colorSpace='rgb';
end

if strcmp(colorSpace,'lab')
    im_out=double(RGB2Lab(im_in,0))/255;
    im_out(:,:,2:3)=im_out(:,:,2:3)*3-1.5;  %��uin8�����ݵĹ�һ��У��
elseif strcmp(colorSpace,'xyz')
    cform=makecform('srgb2xyz');
    im_out=applycform(im_in,cform);
    im_out=im_out/100;  %��Χ��һ��
elseif strcmp(colorSpace,'hsv')
    im_out=rgb2hsv(im_in);
else
    im_out=im_in;
end
    
end

%% ͼ�����Ļ�
function im_out=centralization(im_in,centra)
% ʹ��cos����͹��ͼ����������
%   @im_in      ����ͼ��
%   @centra     �������ַ�ʽ
%   @im_out     �������ֵ�ͼ��

if centra==0
    im_out=im_in;
    return;
end

% 1.��������
[n,m,c]=size(im_in);
cn=(n+1)/2;
cm=(m+1)/2;
ly=([1:n]-cn)/n;
lx=([1:m]-cm)/m;

if strcmp(centra,'cos')             %cos����
    cosy=cos(ly*pi);
    cosx=cos(lx*pi);
    cover=cosy'*cosx;
elseif strcmp(centra,'binomial')    %����ʽ����
    ky=1-ly.*ly*2;
    kx=1-lx.*lx*2;
    cover=ky'*kx;
else
    im_out=im_in;
    return;
end

% ִ��ͼ������
im_out=im_in.*cover(:,:,ones(1,c));

end

%% ʹ��DCT�任�����ֿ�ѡ��Ƶ��任������������ͼ��
%   sign������
%   sigmod������
%   log����
%   �ײвFR
%   ���⻯�任
%   SSS
function ft=featureMap(im_in,ft_param)
%   @im_in      �����ͼ��
%   @ft_param   ѡ�õ�Ƶ��������ȡ����������
%   @ft         ����ͼ

[n,m,c]=size(im_in);
dct_channels=cell(c,1);
ft_channels=cell(c,1);
weight=ones(1,c);
    
way=ft_param.way;

% % ���ɱ���Ƶ��
% cn=(n+1)/2;
% cm=(m+1)/2;
% ly=([1:n]-cn)/n;
% lx=([1:m]-cm)/m;
% 
% cosy=cos(ly*pi);
% cosx=cos(lx*pi);
% cover=1-cosy'*cosx; %��������
% 
% backgrd=cell(c,1);
% for i=1:c
%     if strcmp(way,'SSS')
%         backgrd{i}=abs(fft2(im_in(:,:,i).*cover));
%     else
%         backgrd{i}=abs(dct2(im_in(:,:,i).*cover));
%     end
% end

% �������ͨ������ͼ
for i=1:c
    dct_channels{i}=dct2(im_in(:,:,i));
%     dct_channels{i}=dct_channels{i}.*(1-backgrd{i}./abs(dct_channels{i}));
    
    %��Ϣͼ
    if strcmp(way,'sign')
        msg_mat=idct2(sign(dct_channels{i}));
    elseif strcmp(way,'sigmod')
        a=sqrt(mean(dct_channels{i}(:).^2));
        msg_mat=idct2(sigmf(dct_channels{i},[1/a,0])*2-1);
    elseif strcmp(way,'frequency equalization')
        if ~isfield( ft_param, 'histNum' )
            ft_param.histNum=4;
        elseif isempty(ft_param.histNum)
            ft_param.histNum=4;
        end
        msg_mat=idct2(frequencyEqualization(dct_channels{i},ft_param.histNum));
    elseif strcmp(way,'log')
        a=sqrt(mean(dct_channels{i}(:).^2));
        msg_mat=idct2(sign(dct_channels{i}).*log(abs(dct_channels{i})/a+1));
    elseif strcmp(way,'SR') %�ײв
        a=abs(dct_channels{i});
        p=dct_channels{i}./a;
        
        la=log(a+1);
        fr=filter2(ones(5,1)/5,la);
        fr=filter2(ones(1,5)/5,fr);
        fr=la-fr;
        
        msg_mat=idct2(fr.*p);
    elseif strcmp(way,'contrast')	%�Աȶ���ǿ��
        if i==1
            filter_sz=size(dct_channels{i});
            x=[1:filter_sz(2)];
            y=[1:filter_sz(1)];
            kernelF=sigmf(y',[1,1])*sigmf(x,[1,1]);
%             kernelF=ones(filter_sz);
%             kernelF(1,x)=0;kernelF(y,1)=0;
        end
        msg_mat=idct2(dct_channels{i}.*kernelF);
    elseif strcmp(way,'SSS')	%��߶���������
        [ft_channels{i},weight(i)]=sssFeatureMap(im_in(:,:,i),1);
        continue;
    else
        
    end
    
    ft_channels{i}=msg_mat.*msg_mat; %����ͼ
    weight(i)=(std(ft_channels{i}(:))/(mean(ft_channels{i}(:))+0.000000001))^4;   %ͨ��Ȩ��
end

% ����ͼͨ���ں�
% ���ݸ���ɫ��ƽ��ǿ����ͼ��ƽ��ǿ��֮������𣬼���Ȩֵ
if c>1
    ft=ft_channels{1};
    for i=2:c
        ft=ft+ft_channels{i}*weight(i);
    end
    ft=ft/sum(weight);
else
    ft=ft_channels{1};
end
end

function fe_out=frequencyEqualization(fq_im,hist_num)
% Ƶ����⻯����
% ��Ƶ��ǿ�Ⱦ��⻯ӳ�䵽[-1,1]֮��
%   @fq_im      �����ͼ��
%   @hist_num   ֱ��ͼ����
%   @fe_out     ���⻯���ͼ��

if ~exist( 'hist_num', 'var' )
    hist_num=4;
elseif isempty(hist_num)
    hist_num=4;
end

% �����ֱ�ͳ��ֱ��ͼ
max_p=max(fq_im(:));
min_p=min(fq_im(:));

st_hn=hist_num*2;       %ͳ��ֱ��ͼ����
hist_p=zeros(st_hn,1);    %������ֱ��ͼ
hist_n=zeros(st_hn,1);    %������ֱ��ͼ

map_p=ceil(fq_im/(max_p/st_hn));
map_n=ceil(fq_im/(min_p/st_hn));

for i=1:st_hn
    eq_mat=(map_p==i);
    hist_p(i)=sum(eq_mat(:));
    
    eq_mat=(map_n==i);
    hist_n(i)=sum(eq_mat(:));
end
hist_p=hist_p/sum(hist_p);  %��һ��
hist_n=hist_n/sum(hist_n);

% ����ӳ��
fix_p=zeros(st_hn,1);
fix_n=zeros(st_hn,1);

cur_pst=0;
cur_ngt=0;
for i=1:st_hn
    cur_pst=cur_pst+hist_p(i);
    cur_ngt=cur_ngt+hist_n(i);
    
    fix_p(i)=ceil(cur_pst*hist_num);
    fix_n(i)=-ceil(cur_ngt*hist_num);
end

fix_p=fix_p/hist_num;
fix_n=fix_n/hist_num;

% ���⻯
fe_out=zeros(size(fq_im));
for i=1:st_hn
    eq_mat=(map_p==i);
    fe_out(eq_mat)=fix_p(i);
    
    eq_mat=(map_n==i);
    fe_out(eq_mat)=fix_n(i);
end
end

function [ft,sum_w]=sssFeatureMap(im_in,max_pix)
%����SSS��������һ��ͨ������ͼ

%1.����FFTƵ��ǿ�ȼ���λ
fft_map=fft2(im_in);
a_map=abs(fft_map);     %����
fft_map=fft_map./(a_map+0.00001*(a_map==0)); %��λ

a_map=fftshift(a_map);  %����Ƶ�ŵ�ͼ������
a_map=log(a_map+1);

% ���������
x_sz=[1:31]-16;

% ��ξ���
ft=zeros(size(im_in));
sum_w=0;

for sz=0:7
    kernel_x=exp(-x_sz.^2/(0.25*2^sz));
    kernel_x=kernel_x./sum(kernel_x);

    % �����׾���
    cur_ft=imfilter(a_map,kernel_x);
    cur_ft=imfilter(cur_ft,kernel_x');
    cur_ft=fftshift(cur_ft);
    cur_ft=exp(cur_ft)-1;
    
    % ����ͼ
    cur_ft=ifft2(cur_ft.*fft_map);
    cur_ft=cur_ft.*conj(cur_ft);
    cur_ft=cur_ft./max(cur_ft(:));  %��һ������
    
    % ��������ͼ��
%     hmp=ceil(cur_ft*4); %�ֲ�ͳ�ƽ��
%     hp=zeros(4,1);      %ͳ�Ƹ���
%     for j=1:4
%         hp(j)=sum(sum(hmp==j));
%     end
%     hp=hp/pix_n;
%     hs=-hp'*(log(hp+0.01));%��
%     
%     if hs<min_hs
%         ft=cur_ft;
%         min_hs=hs;
%     end

    weight=(std(cur_ft(:))/mean(cur_ft(:))+0.0001)^8;
    
    if sz==0
        ft=weight*cur_ft;
    else
        ft=ft+weight*cur_ft;
    end
    sum_w=sum_w+weight;
end
ft=ft/sum_w;
end
%% ʹ�ü��ֿ�ѡ���˲�����������ͼ��
%   gauss��ͨ�˲���
%   ��˹��ִ�ͨ�˲���
%   
function sl_map=salientMap(ft_map,sl_param)
%   @ft_map     ����ͼ
%   @sl_param   ѡ�õ��˲�������������
%   @sl_map     ����ͼ

if ~isfield( sl_param, 'kernel' )
    sl_param.kernel='gaussLow';
elseif isempty(sl_param.kernel)
    sl_param.kernel='gaussLow';
end

if ~isfield( sl_param, 'size' )
    sl_param.size=[0.1,0.5];
elseif isempty(sl_param.size)
    sl_param.size=[0.1,0.5];
end

% ��������ͼDCT
ft_F=dct2(ft_map);

% �����˲���
[n,m]=size(ft_F);
kernel=sl_param.kernel;
if strcmp(kernel,'gaussLow')
    fq=1./min(sl_param.size);	%Ŀ��ߴ��Ӧ��ֹƵ��
    kernelF=gaussFilterFq([n,m],[0,0],[fq,fq]);
elseif strcmp(kernel,'gaussBand')
    fq=(1./sl_param.size(1)+1./sl_param.size(2))/2;	%Ŀ��ߴ��Ӧ��ֹƵ��
    df=abs(1./sl_param.size(1)-1./sl_param.size(2));
    kernelF=gaussFilterFq([n,m],[fq,fq],[df,df]);
elseif strcmp(kernel,'DOG')
    fq=1./sl_param.size;        %Ƶ�ʷ�Χ
    ef=max(fq);  %��ֹƵ��
    sf=min(fq);                 %��ʼƵ��
    kernelF=gaussFilterFq([n,m],[0,0],[ef,ef])-gaussFilterFq([n,m],[0,0],[sf,sf]);
elseif strcmp(kernel,'biasBand')
    %����Ƶ�ʷ�Χ�������
    fq=1./sl_param.size;    %Ƶ�ʷ�Χ
    fq_min=min(fq);fq_max=max(fq);
    b=log(0.1)/(2*fq_min*log(fq_max/2/fq_min)-fq_max+2*fq_min); %����ֵ��0.1
    a=2*b*fq_min;   %����ǰһ��
    
    kernelF=biasBandFq([n,m],a,b);
else
    
end

% �������ͼ
sl_map=idct2(ft_F.*kernelF);

% ��һ��
sl_map=sl_map./max(sl_map(:));
end

function kernelF=gaussFilterFq(filter_sz,u0,delta)
% ����DCT�任��2άƵ���˹�˲���
%   @filter_sz  �˲����ߴ磬��ʽΪ[height,width]
%   @u0         ��ֵ����ʽΪ[u0_y,u0_x]
%   @delta      ��׼���ʽΪ[delta_y,delta_x]

dx=[1:filter_sz(2)]-u0(2);
dy=[1:filter_sz(1)]-u0(1);
delta=2*delta.^2;

kx=exp(-dx.*dx/delta(2));
ky=exp(-dy.*dy/delta(1));
kernelF=ky'*kx;
end

function kernelF=biasBandFq(filter_sz,a,b)
% ����DCT�任��2άƵ��x^a*exp(-b*x)�˲���
%   @filter_sz  �˲����ߴ磬��ʽΪ[height,width]
%   @a          ���ݲ���
%   @b      	ָ������

x=[0:filter_sz(2)-1];
y=[0:filter_sz(1)-1];

max_num=(a/b)^a*exp(-a);
kx=x.^a.*exp(-b*x)/max_num;
ky=y.^a.*exp(-b*y)/max_num;
kernelF=ky'*kx;
end 