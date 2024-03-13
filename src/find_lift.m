
%% Calcule la fonction de lifting, depuis un Array<Polyhedron>
% cherche une solution de la forme f(x) = max[i=1..N](a_i' * x + b_i)
% avec les contraintes: 
% - f est bornée sur l'espace utile
% - le maximum est strict (f(x) >= a_j' * x + b_j)
function [oa, ob] = find_lift(Obstacles)
    min_convexity = 0.1;
    upper_bound = 1000;

    N = size(Obstacles, 1); % nombre d'obstacles
    D = Obstacles(1).Dim; % dimension de l'espace
    
    a = sdpvar(N, D);
    b = sdpvar(N, 1);

    constraints = [];

    for obs = 1:N
        for vertex_id = 1:size(Obstacles(obs).V, 1)
            vertex = Obstacles(obs).V(vertex_id)';
            for other = 1:N
                if other ~= obs
                    constraints = [constraints; a(obs,:) * vertex + b(obs) >= a(other,:) * vertex + b(other) + min_convexity];
                end
            end
        end
        constraints = [constraints; a(obs,:) * Obstacles(obs).V(1)' + b(obs) <= upper_bound];
        constraints = [constraints; a(obs,:) * Obstacles(obs).V(1)' + b(obs) >= 0]; 
    end

    e = cat(2, a, b);
    optimize(constraints, trace(e'*e));
    oa = value(a);
    ob = value(b);
end