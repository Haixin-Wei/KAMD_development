figure(12);
length1 = 100;
for i = 1: 1000000 - length1
    if (abs(md_phi(i) - (-75)) < 0.5 && abs(md_psi(i) - (-20)) < 0.5)
        scatter(md_phi(i+length1),md_psi(i+length1),'o','blue');
        hold on;
    end
end
hold off