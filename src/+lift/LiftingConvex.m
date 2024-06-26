
classdef LiftingConvex < Lifting
    properties
        oa (:, :) double;
        ob (:, 1) double;
        diag (1, 1);
        bbox (1, 1) Polyhedron = Polyhedron();
        partition (:, 1) Polyhedron = [];
    end

    methods

        function diags = getDiagnostics(self)
            % Gets the single diagnostic for this method
            diags = self.diag;
        end


        function out = isSuccess(self)
            %% Success is achieved if the minimal convexity is greater than 0
            error("not implemented")
        end


        function part = getPartition(self, bbox)
        %% Calculates the partition for this lifting, possibly overwriting the bounding box
            arguments
                self (1, 1) LiftingLinear;
                bbox (1, 1) Polyhedron = Polyhedron();
            end

            if (size(self.partition, 1) > 0 && (bbox.Dim == 0 || self.bbox.eq(bbox)))
                part = self.partition;
                return;
            end

            if (bbox.Dim ~= 0)
                self.bbox = bbox;
            end

            if (self.bbox.Dim == 0)
                error("Cannot get partition from LiftingConvex without a boundiing box")
            end

            self.partition = lift.partition(self.oa, self.ob, self.bbox);
            part = self.partition;
        end


        function self = LiftingConvex(Obstacles, options)
        %% Constructor and lift finding function for linear method
            arguments
                Obstacles (:, 1) Polyhedron;
                options (1, 1);
            end

            import util.*;

            if (isfield(options, "bbox"))
                self.bbox = options.bbox;
            end

            N = size(Obstacles, 1);
            D = Obstacles(1).Dim;

            min_convexity = 0.001;
            if (isfield(options, "min_cvx"))
                min_convexity = options.min_cvx;
            end

            a = sdpvar(N, D);
            b = sdpvar(N, 1);
            e = reshape(cat(2, a, b)', [], 1);

            % Number of constraints to create
            N_constr = 0;
            for obs = 1:N
                N_constr = N_constr + (N-1) * size(Obstacles(obs).V, 1);
            end

            cmat = zeros(N_constr, N * (D+1));
            i = 0;

            for obs = 1:N

                for vertex_id = 1:size(Obstacles(obs).V, 1)
                    vertex = Obstacles(obs).V(vertex_id, :)';

                    assert_shape(vertex, [D 1]);
                    for other = 1:N
                        if other ~= obs

                            i = i+1;

                            cmat(i, (D+1)*obs) = 1;
                            cmat(i, (D+1)*other) = -1;
                            cmat(i, (D+1)*(obs-1)+1 : (D+1)*(obs-1)+D) = vertex';
                            cmat(i, (D+1)*(other-1)+1 : (D+1)*(other-1)+D) = -vertex';

                        end
                    end
                end
            end

            constraints = cmat * e >= min_convexity;
            constraints = [constraints; -1000 <= e <= 1000];

            % adding a constraint to force convexity strictly positive actually makes things lees efficient
            ops = sdpsettings;
            ops.debug = false;
            ops.verbose = false;
            if (isfield(options, 'solver'))
                ops.solver = options.solver;
            end
            if( isfield(options, 'debug'))
                ops.debug = options.debug;
            end
            if( isfield(options, 'verbose'))
                ops.verbose = options.verbose;
            end
            if( isfield(options, 'sdp'))
                ops = options.sdp;
            end

            self.diag = optimize(constraints, norm(e, 2), ops);
            self.oa = value(a);
            self.ob = value(b);
        end
    end
end
