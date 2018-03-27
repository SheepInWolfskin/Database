
import java.sql.*;
import java.util.List;
import java.util.ArrayList;

// If you are looking for Java data structures, these are highly useful.
// Remember that an important part of your mark is for doing as much in SQL (not Java) as you can.
// Solutions that use only or mostly Java will not receive a high mark.
//import java.util.Map;
//import java.util.HashMap;
//import java.util.Set;
//import java.util.HashSet;
public class Assignment2 extends JDBCSubmission {

    public Assignment2() throws ClassNotFoundException {

        Class.forName("org.postgresql.Driver");
    }

    @Override
    public boolean connectDB(String url, String username, String password) {
        // Implement this method!
        try {
            connection = DriverManager.getConnection(url, username, password);
            PreparedStatement ps = connection.prepareStatement("SET search_path TO MARKUS;");
            ps.execute();
            
            return true;
        } catch (SQLException se) {
            return false;
        }
    }

    @Override
    public boolean disconnectDB() {
        try {
            connection.close();
            return true;
        } catch (SQLException se) {
            return false;
        }
    }

    @Override
    public ElectionCabinetResult electionSequence(String countryName) {
    
        PreparedStatement ps;
        ResultSet result;
        
        try{
        
            String getCountryId = "SELECT sub.election_id, ca.id FROM cabinet ca RIGHT JOIN (SELECT election.id AS election_id, e_date "+ 
                                  "FROM election, country WHERE country.name = ? AND " +
                                  "country.id = election.country_id) sub ON sub.election_id = ca.election_id " + 
                                  "ORDER BY EXTRACT(year FROM e_date) DESC;";
            ps = connection.prepareStatement(getCountryId);
            ps.setString(1, countryName);
            result = ps.executeQuery();
            
            List<Integer> election_list = new ArrayList<Integer>(); 
            List<Integer> cabinet_list = new ArrayList<Integer>();
            Integer e_id;
            Integer c_id;
            
            while (result.next()) {
                e_id = result.getInt("election_id");
                c_id = result.getInt("id");
                election_list.add(e_id);
                cabinet_list.add(c_id);
            }
            result.close();
            
            ElectionCabinetResult result_array = new ElectionCabinetResult(election_list, cabinet_list);
            
            return result_array;
            
        }catch (SQLException se) {
            System.out.println(se);
            return null;
            
        }
        
    }

    @Override
    public List<Integer> findSimilarPoliticians(Integer politicianName, Float threshold) {
    
        PreparedStatement ps;
        ResultSet result;
        ResultSet result2;
        
        try{
            // get the chose politician to compare
            String getInfo = "SELECT id, description || ' ' || comment AS info FROM politician_president WHERE id = ?";
            ps = connection.prepareStatement(getInfo);
            ps.setInt(1, politicianName);
            result = ps.executeQuery();
    
            String chosen_info = null;
            
            if (result.next()){
                chosen_info= result.getString("info");
            }
            result.close();
            
            // get every other politician.
            String getAll = "SELECT id, description || ' ' || comment AS info FROM politician_president WHERE id != ?";
            ps = connection.prepareStatement(getAll);
            ps.setInt(1, politicianName);
            result2 = ps.executeQuery();
            
            String loop_info;
            Integer loop_id;
            List<Integer> id_list = new ArrayList<Integer>(); 
            
            //start comparing
            while (result2.next()){
                loop_id = result2.getInt("id");
                loop_info = result2.getString("info");
                if (similarity(loop_info, chosen_info) >= threshold){
                    id_list.add(loop_id);
                }
            }
            
            System.out.println(id_list);
            return id_list;
            
        }catch (SQLException se) {
        
            System.out.println(se);
            return null;
        }
    }

    public static void main(String[] args) {
        // You can put testing code in here. It will not affect our autotester.
        Assignment2 test = null;
        try {
                test = new Assignment2();
        } catch (ClassNotFoundException se) {
                System.out.println("Init failed");
                return;
        }
        if (test.connectDB("jdbc:postgresql://localhost:5432/csc343h-guanyich?currentSchema=parlgov", "guanyich", "")) {
                System.out.println("Connected to database.");
        } else {
                System.out.println("Connection failed");
        }
        test.electionSequence("Germany");
        
        Float threshold = 0.0f;
        Integer politicianName = 148;
        
        test.findSimilarPoliticians(politicianName, threshold);

        System.out.println("Hello");
    }

}

