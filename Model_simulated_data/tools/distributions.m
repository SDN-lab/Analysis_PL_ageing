load('participant_params.mat')

pdb=fitdist(betas,'gamma');

pd=fitdist([self_alpha;other_alpha;noone_alpha],'beta');
pds=fitdist(self_alpha,'beta');
pdo=fitdist(other_alpha,'beta');
pdn=fitdist(noone_alpha,'beta');

X = 0:.01:1;
y1 = betapdf(X,pds.a,pds.b);
y2 = betapdf(X,pdo.a,pdo.b);
y3 = betapdf(X,pdn.a,pdn.b);
y4 = betapdf(X,1.1,1.1);

figure
plot(X,y1,'Color','r','LineWidth',2)
hold on
plot(X,y2,'LineStyle','-.','Color','b','LineWidth',2)
plot(X,y3,'LineStyle',':','Color','g','LineWidth',2)
plot(X,y4,'Color','black','LineWidth',2)
hold off

g1 = gampdf(X,pdb.a,pdb.b);
g2 = gampdf(X,1.2,5);

figure
plot(X,g1,'Color','r','LineWidth',2)
hold on
plot(X,g2,'Color','black','LineWidth',2)
hold off

hist(self_alpha)
hist(betas)