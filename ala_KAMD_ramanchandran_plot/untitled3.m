figure(11);
length1 = 100;
for i = 1: 1000000 - length1
    if (abs(kamd_phi(i) - (-75)) < 0.5 && abs(kamd_psi(i) - (-20)) < 0.5)
        scatter(kamd_phi(i+length1),kamd_psi(i+length1),'o','blue');
        hold on;
    end
end
hold off