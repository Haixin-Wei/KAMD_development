n=0;
for i = 1 : 10007
    if md_phi(i+1)*md_phi(i) < 0
        n = n+1;
    end
    if mod(i,1000) == 7
        if md_phi(i+1)*md_phi(i) < 0
            n = n-1;
        end
    end

end
